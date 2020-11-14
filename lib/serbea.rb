require "tilt"
require "tilt/erubi"

require "serbea/helpers"
require "serbea/pipeline"
require "serbea/template_engine"

module Tilt
  class SerbeaTemplate < ErubiTemplate
    def prepare
      @options.merge!(
        outvar: "@_erbout",
        bufval: "Serbea::Buffer.new", 
        literal_prefix: "{%",
        literal_postfix: "%}",
        engine_class: Serbea::TemplateEngine
      )
      super
    end

    def encoding
      @src.encoding
    end
  end
end

Tilt.register Tilt::SerbeaTemplate, "serb"

if defined?(Rails::Railtie)
  class Railtie < ::Rails::Railtie
    initializer :serbea do |app|
      ActiveSupport.on_load(:action_view) do
        require "serbea/rails_support"

        ActionController::Base.include Serbea::Rails::FrontmatterControllerActions
      end
    end
  end
end

if defined?(Bridgetown)
  require "serbea/bridgetown_support"
end
