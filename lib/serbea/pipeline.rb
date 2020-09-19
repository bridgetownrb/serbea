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

    def initialize(context, value)
      @context = context
      @value = value
    end

    def filter(sym, *aargs)
      if @value.respond_to?(sym)
        @value = @value.send(sym, *aargs)
      elsif @context.respond_to?(sym)
        @value = @context.send(sym, @value, *aargs)
      else
        "Serbea warning: Filter not found: #{sym}".tap do |warning|
          raise_on_missing_filters ? raise(warning) : puts(warning)
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
