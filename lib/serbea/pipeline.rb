module Serbea
  class Pipeline
    def self.exec(template, input: (no_input_passed = true; nil), include_helpers: nil)
      anon = Class.new do
        include Serbea::Helpers

        attr_accessor :input, :output
      end

      if include_helpers
        anon.include include_helpers
      end

      pipeline_obj = anon.new
      pipeline_obj.input = input unless no_input_passed

      full_template = "{{ #{template} | assign_to: :output }}"

      tmpl = Tilt::SerbeaTemplate.new { full_template }
      tmpl.render(pipeline_obj)

      pipeline_obj.output
    end

    def self.output_processor=(processor)
      @output_processor = processor
    end
    def self.output_processor
      @output_processor ||= lambda do |input|
        # no-op
        input
      end
    end

    def self.raise_on_missing_filters=(config_boolean)
      @raise_on_missing_filters = config_boolean
    end
    def self.raise_on_missing_filters
      @raise_on_missing_filters ||= false
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

    # TODO: clean this up somehow and still support Ruby 2.5..3.0!
    def filter(name, *args, **kwargs)
      if @value.respond_to?(name) && !self.class.value_methods_denylist.include?(name)
        if args.last.is_a?(Proc)
          real_args = args.take(args.length - 1)
          block = args.last
          unless kwargs.empty?
            @value = @value.send(name, *real_args, **kwargs, &block)
          else
            @value = @value.send(name, *real_args, &block)
          end
        else
          unless kwargs.empty?
            @value = @value.send(name, *args, **kwargs)
          else
            @value = @value.send(name, *args)
          end
        end
      elsif @context.respond_to?(name)
        unless kwargs.empty?
          @value = @context.send(name, @value, *args, **kwargs)
        else
          @value = @context.send(name, @value, *args)
        end
      else
        "Serbea warning: Filter not found: #{name}".tap do |warning|
          self.class.raise_on_missing_filters ? raise(warning) : STDERR.puts(warning)
        end
      end

      self
    end

    def to_s
      self.class.output_processor.call @value.to_s
    end
  end
end
