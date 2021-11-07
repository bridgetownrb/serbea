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
        bufval: "Serbea::OutputBuffer.new", 
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
