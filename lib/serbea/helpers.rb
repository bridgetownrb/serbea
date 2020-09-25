module Serbea
  module Helpers
    def self.included(mod)
      Serbea::Pipeline.deny_value_method %i(prepend append)
    end

    def capture(obj=nil)
      previous_buffer_state = @_erbout
      @_erbout = +""
      result = obj ? yield(obj) : yield
      @_erbout = previous_buffer_state
    
      result.respond_to?(:html_safe) ? result.html_safe : result
    end
  
    def pipeline(context, value)
      Pipeline.new(context, value)
    end
  
    def helper(name, &block)
      self.class.send(:define_method, name, &block)
    end
  
    def h(input)
      Erubi.h(input)
    end
    alias_method :escape, :h

    def prepend(old_string, new_string)
      "#{new_string}#{old_string}"
    end

    def append(old_string, new_string)
      "#{old_string}#{new_string}"
    end
  end
end
