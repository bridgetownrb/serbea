module Serbea
  class TemplateEngine < Erubi::CaptureEndEngine
    FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

    def self.render_directive=(directive)
      @render_directive = directive
    end
    def self.render_directive
      @render_directive ||= "render"
    end
  
    def self.has_yaml_header?(template)
      template.lines.first&.match? %r!\A---\s*\r?\n!
    end
  
    def initialize(input, properties={})
      properties[:regexp] = /{%(\:?={1,2}|-|\#|%|\:)?(.*?)([-=])?%}([ \t]*\r?\n)?/m
      properties[:strip_front_matter] = true unless properties.key?(:strip_front_matter)
      super process_serbea_input(input, properties), properties
    end
  
    def add_postamble(postamble)
      src << postamble
      src << "@_erbout.html_safe" if postamble.respond_to?(:html_safe)
  
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
          string = string.post_match
  #        yaml_data = SafeYAML.load(template.captures[0])
        end
      end
  
      # Ensure the raw "tag" will strip out all ERB-style processing
      until string.empty?
        text, code, string = string.partition(/{% raw %}.*?{% endraw %}/m)
  
        buff << text
        if code.length > 0
          buff << code.
            sub("{% raw %}", "").
            sub("{% endraw %}", "").
            gsub("{{", "__RAW_START_PRINT__").
            gsub("}}", "__RAW_END_PRINT__").
            gsub("{%", "__RAW_START_EVAL__").
            gsub("%}", "__RAW_END_EVAL__")
        end
      end

      # Process the pipeline outputs
      string = buff
      buff = ""
      until string.empty?
        text, code, string = string.partition(/{{.*?}}/m)
  
        buff << text
        if code.length > 0
          processed_filters = false
  
          code = code.gsub('\|', "__PIPE_C__")
  
          subs = code.gsub(/\s*\|\s+(.*?)\s([^|}]*)/) do
            args = $2
            args = nil if args.strip == ""
            prefix = processed_filters ? ")" : "))"
            processed_filters = true
            "#{prefix}.filter(:#{$1.chomp(":")}" + (args ? ", #{args}" : "")
          end
  
          pipeline_suffix = processed_filters ? ") %}" : ")) %}"
  
          buff << subs.sub("{{", "{%= pipeline(self, (").sub("}}", pipeline_suffix).gsub("__PIPE_C__", '\|')
        end
      end

      # Process the render directives
      string = buff
      buff = ""
      until string.empty?
        text, code, string = string.partition(/{%@.*?%}/m)
  
        buff << text
        if code.length > 0
          code.sub! /^\{%@/, ""
          code.sub! /%}$/, ""
          unless ["end", ""].include? code.strip
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
              buff << "{%:= #{self.class.render_directive}#{pieces.join(" ")} %}"
            else
              pieces.last << ")"
              buff << "{%= #{self.class.render_directive}#{pieces.join(" ")} %}"
            end
          else
            buff << "{%: end %}"
          end
        end
      end

      buff
    end
  
    private
  
    # Handle the {%:= and {%:== tags
    # Carried over from the Erubi class but with changed indicators
    def handle(indicator, code, tailch, rspace, lspace)
      case indicator
      when ':=', ':=='
        rspace = nil if tailch && !tailch.empty?
        add_text(lspace) if lspace
        escape_capture = !((indicator == ':=') ^ @escape_capture)
        src << "begin; (#{@bufstack} ||= []) << #{@bufvar}; #{@bufvar} = #{@bufval}; #{@bufstack}.last << #{@escapefunc if escape_capture}((" << code
        add_text(rspace) if rspace
      when ':'
        rspace = nil if tailch && !tailch.empty?
        add_text(lspace) if lspace
        result = @yield_returns_buffer ? " #{@bufvar}; " : ""
        src << result << code << ")).to_s; ensure; #{@bufvar} = #{@bufstack}.pop; end;"
        add_text(rspace) if rspace
      else
        super
      end
    end
  end # class
end