require "serbea/rouge_lexer"

module Bridgetown
  class SerbeaView < RubyTemplateView
    include Serbea::Helpers

    def partial(partial_name, options = {})
      options.merge!(options[:locals]) if options[:locals]
      options[:content] = yield if block_given?

      partial_segments = partial_name.split("/")
      partial_segments.last.sub!(%r!^!, "_")
      partial_name = partial_segments.join("/")

      Tilt::SerbeaTemplate.new(
        site.in_source_dir(site.config[:partials_dir], "#{partial_name}.serb")
      ).render(self, options)
    end

    def markdownify(&block)
      content = Bridgetown::Utils.reindent_for_markdown(capture(&block))
      converter = site.find_converter_instance(Bridgetown::Converters::Markdown)
      md_output = converter.convert(content).strip
      @_erbout << md_output
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

      def matches(ext, convertible = nil)
        if convertible
          if convertible.data[:template_engine] == "serbea" ||
              (convertible.data[:template_engine].nil? &&
                @config[:template_engine] == "serbea")
            return true
          end
        end

        super(ext)
      end

      def output_ext(ext)
        ext == ".serb" ? ".html" : ext
      end
    end
  end
end
