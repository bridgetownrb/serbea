# frozen_string_literal: true

# inspired by https://github.com/haml/haml/blob/main/lib/haml/plugin.rb
module Serbea
  # This module makes Serbea work with Rails using the template handler API.
  class Plugin
    def handles_encoding?; true; end

    def compile(template, source)
      "self.class.include(Serbea::Helpers);" + Tilt::SerbeaTemplate.new { source }.precompiled_template([])
    end

    def self.call(template, source = nil)
      source ||= template.source

      new.compile(template, source)
    end

    def self.initialize_frontmatter
      if defined?(ApplicationHelper)
        Serbea::TemplateEngine.front_matter_preamble = "self.set_page_frontmatter = local_frontmatter = YAML.load"
      
        ApplicationHelper.define_method(:set_page_frontmatter=) do |data|
          @frontmatter ||= HashWithDotAccess::Hash.new
          @frontmatter.update(data)
        end
      
        ApplicationController.before_action { @frontmatter ||= HashWithDotAccess::Hash.new }
      end
    end
  end
end

ActionView::Template.register_template_handler(:serb, Serbea::Plugin)
