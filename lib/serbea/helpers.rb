require "active_support/core_ext/string/output_safety"

module Serbea
  module Helpers
    def self.included(mod)
      Serbea::Pipeline.deny_value_method %i(escape h prepend append assign_to)
    end

    def capture(*args)
      previous_buffer_state = @_erbout
      @_erbout = Serbea::OutputBuffer.new
      result = yield(*args)
      result = @_erbout.presence || result
      @_erbout = previous_buffer_state

      Serbea::OutputBuffer === result ? result.html_safe : result
    end

    def pipeline(context, value)
      Pipeline.new(context, value)
    end

    def helper(name, &helper_block)
      self.class.define_method(name) do |*args, **kwargs, &block|
        capture { helper_block.call(*args, **kwargs, &block) }
      end
    end
    alias_method :macro, :helper

    def import(*args, **kwargs, &block)
      helper_names = %i(partial render)
      available_helper = helper_names.find { |meth| respond_to?(meth) }
      raise "Serbea error: no `render' helper is available in #{self.class}" unless available_helper
      available_helper == :partial ? partial(*args, **kwargs, &block) : render(*args, **kwargs, &block)
      nil
    end

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
