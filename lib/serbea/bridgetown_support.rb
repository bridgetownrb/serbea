module Bridgetown
  class SerbeaView < RubyTemplateView
    include Serbea::Helpers

    def partial(partial_name, options = {})
      options.merge!(options[:locals]) if options[:locals]

      partial_segments = partial_name.split("/")
      partial_segments.last.sub!(%r!^!, "_")
      partial_name = partial_segments.join("/")

      Tilt::SerbeaTemplate.new(
        site.in_source_dir(site.config[:partials_dir], "#{partial_name}.serb")
      ).render(self, options)
    end
    
    def markdownify
      previous_buffer_state = @_erbout
      @_erbout = +""
      result = yield
      @_erbout = previous_buffer_state

      content = Bridgetown::Utils.reindent_for_markdown(result)
      converter = site.find_converter_instance(Bridgetown::Converters::Markdown)
      md_output = converter.convert(content).strip
      @_erbout << md_output
    end
  end

  module Converters
    class SerbeaTemplates < Converter
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
    end
  end
end
