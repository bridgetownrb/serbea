require "serbea/rouge_lexer"
require "bridgetown-core"

module Bridgetown
  class SerbeaView < RubyTemplateView
    include Serbea::Helpers

    def partial(partial_name, options = {}, &block)
      options.merge!(options[:locals]) if options[:locals]
      options[:content] = capture(&block) if block

      partial_segments = partial_name.split("/")
      partial_segments.last.sub!(%r!^!, "_")
      partial_name = partial_segments.join("/")

      Tilt::SerbeaTemplate.new(
        site.in_source_dir(site.config[:partials_dir], "#{partial_name}.serb")
      ).render(self, options)
    end

    def markdownify(input = nil, &block)
      content = Bridgetown::Utils.reindent_for_markdown(
        block.nil? ? input.to_s : capture(&block)
      )
      converter = site.find_converter_instance(Bridgetown::Converters::Markdown)
      converter.convert(content).strip
    end
  end

  module Converters
    class SerbeaTemplates < Converter
      priority :highest
      input :serb

      # Logic to do the Serbea content conversion.
      #
      # @param content [String] Content of the file (without front matter).
      # @params convertible [Bridgetown::Page, Bridgetown::Document, Bridgetown::Layout]
      #   The instantiated object which is processing the file.
      #
      # @return [String] The converted content.
      def convert(content, convertible)
        return content if convertible.data[:template_engine] != "serbea"

        serb_view = Bridgetown::SerbeaView.new(convertible)

        serb_renderer = Tilt::SerbeaTemplate.new(convertible.relative_path) { content }

        if convertible.is_a?(Bridgetown::Layout)
          serb_renderer.render(serb_view) do
            convertible.current_document_output
          end
        else
          serb_renderer.render(serb_view)
        end
      end

      def matches(ext, convertible)
        if convertible.data[:template_engine] == "serbea" ||
            (convertible.data[:template_engine].nil? &&
              @config[:template_engine] == "serbea")
          convertible.data[:template_engine] = "serbea"
          return true
        end

        super(ext).tap do |ext_matches|
          convertible.data[:template_engine] = "serbea" if ext_matches
        end
      end

      def output_ext(ext)
        ext == ".serb" ? ".html" : ext
      end
    end
  end
end
