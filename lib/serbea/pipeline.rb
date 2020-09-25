module Serbea
  class Pipeline
    def self.output_processor=(processor)
      @output_processor = processor
    end
    def self.output_processor
      @output_processor ||= lambda do |input|
        # no-op
        input
      end
    end

    def self.deny_value_method(name)
      value_methods_denylist.merge Array(name)
    end
    def self.value_methods_denylist
      @value_methods_denylist ||= Set.new
    end

    def initialize(context, value)
      @context = context
      @value = value
    end

    def filter(name, *args)
      if @value.respond_to?(name) && !self.class.value_methods_denylist.include?(name)
        @value = @value.send(name, *args)
      elsif @context.respond_to?(name)
        @value = @context.send(name, @value, *args)
      else
        "Serbea warning: Filter not found: #{name}".tap do |warning|
          raise_on_missing_filters ? raise(warning) : STDERR.puts(warning)
        end
      end

      self
    end

    def to_s
      self.class.output_processor.call @value.to_s
    end

    def raise_on_missing_filters; false; end
  end
end
