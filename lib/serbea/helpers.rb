require "active_support/core_ext/string/output_safety"

module Serbea
  module Helpers
    def self.included(mod)
      Serbea::Pipeline.deny_value_method %i(escape h prepend append assign_to)
    end

    def capture(*args)
      previous_buffer_state = @_erbout
      @_erbout = Serbea::OutputBuffer.new
      yield(*args)
      result = @_erbout
      @_erbout = previous_buffer_state

      result&.html_safe
    end

    def pipeline(context, value)
      Pipeline.new(context, value)
    end

    def helper(name, &helper_block)
      self.class.define_method(name) do |*args, **kwargs, &block|
        previous_buffer_state = @_erbout
        @_erbout = Serbea::OutputBuffer.new
        result = helper_block.call(*args, **kwargs, &block)
        @_erbout = previous_buffer_state

        result.is_a?(String) ? result.html_safe : result
      end
    end
    alias_method :macro, :helper

    def h(input)
      ERB::Util.h(input.to_s)
    end
    alias_method :escape, :h

    def safe(input)
      input.to_s.html_safe
    end
    alias_method :raw, :safe

    def prepend(old_string, new_string)
      "#{new_string}#{old_string}"
    end

    def append(old_string, new_string)
      "#{old_string}#{new_string}"
    end

    def assign_to(input, varname, preserve: false)
      self.instance_variable_set("@#{varname}", input)
      preserve ? input : nil
    end
  end
end
