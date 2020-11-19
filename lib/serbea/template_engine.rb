require "strscan"

module Serbea
  class OutputBuffer < String
    def concat_to_s(input)
      concat input.to_s
    end

    alias_method :safe_append=, :concat_to_s
    alias_method :append=, :concat_to_s
    alias_method :safe_expr_append=, :concat_to_s
  end

  class TemplateEngine < Erubi::Engine
    FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

    def self.render_directive=(directive)
      @render_directive = directive
    end
    def self.render_directive
      @render_directive ||= "render"
    end

    def self.front_matter_preamble=(varname)
      @front_matter_preamble = varname
    end
    def self.front_matter_preamble
      @front_matter_preamble ||= "frontmatter = YAML.load"
    end
  
    def self.has_yaml_header?(template)
      template.lines.first&.match? %r!\A---\s*\r?\n!
    end
  
    def initialize(input, properties={})
      properties[:regexp] = /{%(={1,2}|-|\#|%)?(.*?)([-=])?%}([ \t]*\r?\n)?/m
      properties[:strip_front_matter] = true unless properties.key?(:strip_front_matter)
      super process_serbea_input(input, properties), properties
    end
  
    def add_postamble(postamble)
      src << postamble
      src << "#{@bufvar}.html_safe"
  
      src.gsub!("__RAW_START_PRINT__", "{{")
      src.gsub!("__RAW_END_PRINT__", "}}")
      src.gsub!("__RAW_START_EVAL__", "{%")
      src.gsub!("__RAW_END_EVAL__", "%}")
    end
  
    def process_serbea_input(template, properties)
      buff = ""
  
      string = template.dup
      if properties[:strip_front_matter] && self.class.has_yaml_header?(string)
        if string = string.match(FRONT_MATTER_REGEXP)
          require "yaml" if self.class.front_matter_preamble.include?(" = YAML.load")

          string = "{% #{self.class.front_matter_preamble} <<~YAMLDATA\n" + 
            string[1].sub(/^---\n/,'') +
            "YAMLDATA\n%}" +
            string[2].sub(/^---\n/, '') +
            string.post_match
        end
      end
  
      # Ensure the raw "tag" will strip out all ERB-style processing
      until string.empty?
        text, code, string = string.partition(/{% raw %}(.*?){% endraw %}/m)
  
        buff << text
        if code.length > 0
          buff << $1.
            gsub("{{", "__RAW_START_PRINT__").
            gsub("}}", "__RAW_END_PRINT__").
            gsub("{%", "__RAW_START_EVAL__").
            gsub("%}", "__RAW_END_EVAL__")
        end
      end

      # Process any pipelines
      string = buff
      buff = ""
      until string.empty?
        text, code, string = string.partition(/{{(.*?)}}/m)
  
        buff << text
        if code.length > 0
          original_line_length = code.lines.size

          s = StringScanner.new($1)
          escaped_segment = ""
          segments = []
          until s.eos?
            portion = s.scan_until(/\|>?/)
            if portion
              if portion.end_with?('\|')
                # the pipe is escaped, so save that for later
                escaped_segment += portion.sub(/\\\|$/, "|")
              elsif escaped_segment.length > 0
                # we already have escaped content, so finish that up
                segments << escaped_segment + portion.sub(/\|>?$/, "")
                escaped_segment = ""
              else
                # let's find out if this is actionable now
                if s.check(/\|/)
                  # nope, the next character is another pipe, so let's escape
                  s.pos += 1
                  escaped_segment += portion + "|"
                else
                  # finally, we have liftoff!
                  segments << portion.sub(/\|>?$/, "")
                end
              end
            else
              # we've reached the last bit of the code
              if escaped_segment.length > 0
                # escape and get the rest
                segments << escaped_segment + s.rest
              else
                # or just the rest will do
                segments << s.rest
              end
              s.terminate
            end
          end

          segments[0] = "pipeline(binding, (#{segments[0].strip}))"
          segments[1..-1].each_with_index do |segment, index|
            filter, args = segment.strip.match(/([^ :]*)(.*)/m).captures
            segments[index + 1] = ".filter(:" + filter
            if args == ""
              segments[index + 1] += ")"
            else
              segments[index + 1] += "," + args.sub(/^:/, "") + ")"
            end
          end

          subs = "{%= #{segments.join} %}"
          buff << subs

          (original_line_length - subs.lines.size).times do
            buff << "\n{% %}" # preserve original line length
          end
        end
      end

      # Process any render directives
      string = buff
      buff = ""
      until string.empty?
        text, code, string = string.partition(/{%@(.*?)%}/m)
  
        buff << text
        if code.length > 0
          code = $1
          unless ["end", ""].include? code.strip
            original_line_length = code.lines.size

            pieces = code.split(" ")
            if pieces[0].start_with?(/[A-Z]/) # Ruby class name
              pieces[0].prepend " "
              pieces[0] << ".new("
            else # string or something else
              pieces[0].prepend "("
            end

            includes_block = false
            pieces.reverse.each do |piece|
              if piece == "do" && (pieces.last == "do" || pieces.last.end_with?("|"))
                piece.prepend(") ")
                includes_block = true
                break
              end
            end

            if includes_block
              buff << "{%= #{self.class.render_directive}#{pieces.join(" ")} %}"
            else
              pieces.last << ")"
              buff << "{%= #{self.class.render_directive}#{pieces.join(" ")} %}"
            end
            (original_line_length - 1).times do
              buff << "\n{% %}" # preserve original directive line length
            end
          else
            buff << "{% end %}"
          end
        end
      end

      buff
    end
  
    private

    def add_code(code)
      @src << code
      @src << ";#{@bufvar};" if code.strip.split(".").first == "end"
      @src << ';' unless code[Erubi::RANGE_LAST] == "\n"
    end

    # pulled from Rails' ActionView
    BLOCK_EXPR = %r!\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z!.freeze

    def add_expression(indicator, code)
      if BLOCK_EXPR.match?(code)
        src << "#{@bufvar}.append= " << code
      else
        super
      end
    end

    # Don't allow == to output escaped strings, as that's the opposite of Rails
    def add_expression_result_escaped(code)
      add_expression_result(code)
    end
  end # class
end