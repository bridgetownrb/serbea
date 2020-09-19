module Serbea
  class ComponentRenderer
    include Helpers

    def initialize(variables = {})
      @variables = variables
    end

    def respond_to_missing?(key, include_private = false)
      @variables.key?(key)
    end

    def method_missing(key)
      return @variables[key] if respond_to_missing?(key)
      
      super
    end
  end
end
