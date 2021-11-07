require "set"
require "active_support/core_ext/string/output_safety"
require "active_support/core_ext/object/blank"

module Serbea
  class Pipeline
    # Exec the pipes!
    # @param template [String]
    # @param locals [Hash]
    # @param include_helpers [Module]
    # @param kwargs [Hash]
    def self.exec(template, locals = {}, include_helpers: nil, **kwargs)
      anon = Class.new do
        include Serbea::Helpers

        attr_accessor :output
      end

      if include_helpers
        anon.include include_helpers
      end

      pipeline_obj = anon.new

      full_template = "{{ #{template} | assign_to: :output }}"

      tmpl = Tilt::SerbeaTemplate.new { full_template }
      tmpl.render(pipeline_obj, locals.presence || kwargs)

      pipeline_obj.output
    end

    # @param processor [Proc]
    def self.output_processor=(processor)
      @output_processor = processor
    end

    # @return [Proc]
    def self.output_processor
      @output_processor ||= lambda do |input|
        (!input.html_safe? && self.autoescape) ? ERB::Util.h(input) : input.html_safe
      end
    end

    def self.autoescape=(config_boolean)
      @autoescape = config_boolean
    end
    def self.autoescape
      @autoescape.nil? ? true : @autoescape
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

    def initialize(binding, value)
      @binding = binding
      @context = binding.receiver
      @value = value
    end

    def filter(name, *args, **kwargs)
      if @value.respond_to?(name) && !self.class.value_methods_denylist.include?(name)
        if args.last.is_a?(Proc)
          real_args = args.take(args.length - 1)
          block = args.last
          @value = @value.send(name, *real_args, **kwargs, &block)
        else
          @value = @value.send(name, *args, **kwargs)
        end
      elsif @context.respond_to?(name)
        @value = @context.send(name, @value, *args, **kwargs)
      elsif @binding.local_variables.include?(name)
        var = @binding.local_variable_get(name)
        if var.respond_to?(:call)
          @value = var.call(@value, *args, **kwargs)
        else
          "Serbea warning: Filter #{name} does not respond to call".tap do |warning|
            self.class.raise_on_missing_filters ? raise(warning) : STDERR.puts(warning)
          end
        end
      else
        "Serbea warning: Filter not found: #{name}".tap do |warning|
          self.class.raise_on_missing_filters ? raise(warning) : STDERR.puts(warning)
        end
      end

      self
    end

    def to_s
      self.class.output_processor.call(@value.is_a?(String) ? @value : @value.to_s)
    end
  end
end
