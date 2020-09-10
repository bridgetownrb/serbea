require "tilt"
require "tilt/erubi"
require 'erubi/capture_end'
require "ostruct"

module SerbeaHelpers
  def capture(obj=nil)
    previous_buffer_state = @_erbout
    @_erbout = +""
    result = obj ? yield(obj) : yield
    @_erbout = previous_buffer_state
  
    result.respond_to?(:html_safe) ? result.html_safe : result
  end

  def pipeline(context, value)
    Serbea::Pipeline.new(context, value)
  end

  def helper(name, &block)
    self.class.send(:define_method, name, &block)
  end

  def h(input)
    Erubi.h(input)
  end
  alias_method :escape, :h
end

module Serbea
  class Pipeline
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
      @value.to_s
    end

    def raise_on_missing_filters; false; end
  end

  class ComponentRenderer
    include SerbeaHelpers

    def initialize(variables = {})
      @variables = variables
    end

    def respond_to_missing?(key)
      @variables.key?(key)
    end

    def method_missing(key)
      @variables[key] if respond_to_missing?(key)
    end
  end
end

class SerbeaEngine < Erubi::CaptureEndEngine
  FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

  def self.has_yaml_header?(template)
    template.lines.first&.match? %r!\A---\s*\r?\n!
  end

  def initialize(input, properties={})
    properties[:regexp] = /{%(\>?={1,2}|-|\#|%|\>)?(.*?)([-=])?%}([ \t]*\r?\n)?/m
    properties[:strip_front_matter] = true unless properties.key?(:strip_front_matter)
    super process_serbea_input(input, properties), properties
  end

  def add_postamble(postamble)
    src << postamble
    src << "@_erbout.html_safe" if postamble.respond_to?(:html_safe)

    src.gsub!("__RAW_START_PRINT__", "{{")
    src.gsub!("__RAW_END_PRINT__", "}}")
    src.gsub!("__RAW_START_EVAL__", "{%")
    src.gsub!("__RAW_END_EVAL__", "%}")
  end

  def process_serbea_input(template, properties)
    buff = ""

    string = template.dup
    if properties[:strip_front_matter] && self.class.has_yaml_header?(string)
      if string = string.match(FRONT_MATTER_REGEXP)
        string = string.post_match
#        yaml_data = SafeYAML.load(template.captures[0])
      end
    end

    until string.empty?
      text, code, string = string.partition(/{% raw %}.*?{% endraw %}/m)

      buff << text
      if code.length > 0
        buff << code.
          sub("{% raw %}", "").
          sub("{% endraw %}", "").
          gsub("{{", "__RAW_START_PRINT__").
          gsub("}}", "__RAW_END_PRINT__").
          gsub("{%", "__RAW_START_EVAL__").
          gsub("%}", "__RAW_END_EVAL__")
      end
    end

    string = buff
    buff = ""
    until string.empty?
      text, code, string = string.partition(/{{.*?}}/m)

      buff << text
      if code.length > 0
        processed_filters = false

        subs = code.gsub(/ *\| +(.*?) ([^|}]*)/) do
          args = $2
          args = nil if args.strip == ""
          prefix = processed_filters ? ")" : "))"
          processed_filters = true
          "#{prefix}.filter(:#{$1.chomp(":")}" + (args ? ", #{args}" : "")
        end

        pipeline_suffix = processed_filters ? ") %}" : ")) %}"
        subs = subs.sub("{{", "{%= pipeline(self, (").sub("}}", pipeline_suffix)

        buff << subs
      end
    end

#      puts buff
    buff
  end # method

  private

  # Handle the <%>= and <%>== tags
  # Carried over from the Erubi class but with changed indicators
  def handle(indicator, code, tailch, rspace, lspace)
    case indicator
    when '>=', '>=='
      rspace = nil if tailch && !tailch.empty?
      add_text(lspace) if lspace
      escape_capture = !((indicator == '>=') ^ @escape_capture)
      src << "begin; (#{@bufstack} ||= []) << #{@bufvar}; #{@bufvar} = #{@bufval}; #{@bufstack}.last << #{@escapefunc if escape_capture}((" << code
      add_text(rspace) if rspace
    when '>'
      rspace = nil if tailch && !tailch.empty?
      add_text(lspace) if lspace
      result = @yield_returns_buffer ? " #{@bufvar}; " : ""
      src << result << code << ")).to_s; ensure; #{@bufvar} = #{@bufstack}.pop; end;"
      add_text(rspace) if rspace
    else
      super
    end
  end
end # class

module Tilt
  class SerbeaTemplate < ErubiTemplate
    def prepare
      @options.merge!(outvar: "@_erbout", engine_class: SerbeaEngine)
      super
    end

    def encoding
      @src.encoding
    end
  end
end

Tilt.register Tilt::SerbeaTemplate, "serb" #, "serbea"

if defined?(Rails::Railtie)
  class Railtie < ::Rails::Railtie
    initializer :serbea do |app|
      ActiveSupport.on_load(:action_view) do
        require "serbea/rails_support"
      end
    end
  end
end
