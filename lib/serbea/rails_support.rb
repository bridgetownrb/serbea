# frozen_string_literal: true

# inspired by https://github.com/haml/haml/blob/main/lib/haml/plugin.rb
module Serbea

  # This module makes Serbea work with Rails using the template handler API.
  class Plugin
    def handles_encoding?; true; end

    def compile(template, source)
      "self.class.include(SerbeaHelpers)\n" + Tilt::SerbeaTemplate.new { source }.precompiled_template([])
    end

    def self.call(template, source = nil)
      source ||= template.source

      new.compile(template, source)
    end

#    def cache_fragment(block, name = {}, options = nil)
#      @view.fragment_for(block, name, options) do
#        eval("_hamlout.buffer", block.binding)
#      end
#    end
  end
end

ActionView::Template.register_template_handler(:serb, Serbea::Plugin)

Serbea::Pipeline.output_processor = lambda do |input|
  input.html_safe? ? input : ActionController::Base.helpers.strip_tags(input)
end
