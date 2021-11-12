# frozen_string_literal: true

require "serbea"
require "hash_with_dot_access"

require "serbea-rails/directives"

module SerbeaRails
  module FrontmatterHelpers
    def set_page_frontmatter=(data)
      @frontmatter ||= HashWithDotAccess::Hash.new
      @frontmatter.update(data)
    end
  end

  module FrontmatterControllerActions
    extend ActiveSupport::Concern

    included do
      Serbea::TemplateEngine.front_matter_preamble = "self.set_page_frontmatter = local_frontmatter = YAML.load"
  
      before_action { @frontmatter ||= HashWithDotAccess::Hash.new }

      helper SerbeaRails::FrontmatterHelpers
    end
  end

  class TemplateHandler
    def handles_encoding?; true; end

    def compile(template, source)
      "self.class.include(Serbea::Helpers);" + Tilt::SerbeaTemplate.new { source }.precompiled_template([])
    end

    def self.call(template, source = nil)
      source ||= template.source

      new.compile(template, source)
    end
  end
end

ActionView::Template.register_template_handler(:serb, SerbeaRails::TemplateHandler)

class Railtie < ::Rails::Railtie
  initializer :serbea do |app|
    ActiveSupport.on_load(:action_view) do
      ActionController::Base.include SerbeaRails::FrontmatterControllerActions
    end
  end
end
