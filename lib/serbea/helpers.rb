require "active_support/core_ext/string/output_safety"

module Serbea
  module Helpers
    def self.included(mod)
      Serbea::Pipeline.deny_value_method %i(escape h prepend append assign_to)
    end

    def capture(obj = nil, &block)
      previous_buffer_state = @_erbout
      @_erbout = Serbea::Buffer.new

      # For compatibility with ActionView, not used by Bridgetown normally
      previous_ob_state = @output_buffer
      @output_buffer = Serbea::Buffer.new

      result = instance_exec(obj, &block)
      if @output_buffer != ""
        # use Rails' ActionView buffer if present
        result = @output_buffer
      end
      @_erbout = previous_buffer_state
      @output_buffer = previous_ob_state

      result&.html_safe
    end
  
    def pipeline(context, value)
      Pipeline.new(context, value)
    end
  
    def helper(name, &helper_block)
      self.class.define_method(name) do |*args, &block|
        previous_buffer_state = @_erbout
        @_erbout = Serbea::Buffer.new
  
        # For compatibility with ActionView, not used by Bridgetown normally
        previous_ob_state = @output_buffer
        @output_buffer = Serbea::Buffer.new
  
        result = helper_block.call(*args, &block)
        if @output_buffer != ""
          # use Rails' ActionView buffer if present
          result = @output_buffer
        end
        @_erbout = previous_buffer_state
        @output_buffer = previous_ob_state
  
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
