require "set"

module Serbea
  class Pipeline
    # If you include this in any regular Ruby template environment (say ERB),
    # you can then use Serbea-style pipeline code within the block, e.g.
    #
    # `pipe "Hello world" do upcase | split(" ") | join(", ") end`
    # => `HELLO, WORLD`
    module Helper
      def pipe(input = nil, &blk)
        Pipeline.new(binding, input).tap { _1.instance_exec(&blk) }.value
      end
    end

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
      tmpl.render(pipeline_obj, locals.empty? ? kwargs : locals)

      pipeline_obj.output
    end

    # @param processor [Proc]
    def self.output_processor=(processor)
      @output_processor = processor
    end

    # @return [Proc]
    def self.output_processor
      @output_processor ||= lambda do |input|
        (!input.html_safe? && self.autoescape) ? Erubi.h(input) : input.html_safe
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

    def self.purge_class_pollution
      @pollution_purged ||= begin
        polluted_methods_list.each do |name|
          define_method name do |*args, **kwargs|
            filter(name, *args, **kwargs)
          end
        end

        true
      end
    end

    def self.polluted_method(name)
      polluted_methods_list.merge Array(name)
    end
    def self.polluted_methods_list
      @polluted_methods_list ||= Set.new(%i(select to_json))
    end

    def initialize(binding, value)
      self.class.purge_class_pollution
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
          "Serbea warning: Filter '#{name}' does not respond to call".tap do |warning|
            self.class.raise_on_missing_filters ? raise(Serbea::FilterMissing, warning) : STDERR.puts(warning)
          end
        end
      else
        "Serbea warning: Filter `#{name}' not found".tap do |warning|
          self.class.raise_on_missing_filters ? raise(Serbea::FilterMissing, warning) : STDERR.puts(warning)
        end
      end

      self
    end

    def to_s
      self.class.output_processor.call(@value.is_a?(String) ? @value : @value.to_s)
    end
  
    def |(*)
      self
    end

    def method_missing(...)
      filter(...)
    end

    def value(callback = nil)
      return @value unless callback

      @value = if callback.is_a?(Proc)
                 callback.(@value)
               else
                 callback
               end
      self
    end
  end
end
