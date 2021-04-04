require "bundler"
require "serbea"
require "ostruct"
require "json"

class FakeComponentRenderer
  include Serbea::Helpers

  def initialize(variables = {})
    @variables = variables
  end

  def respond_to_missing?(key, include_private = false)
    @variables.key?(key)
  end

  def method_missing(key)
    return @variables[key] if respond_to_missing?(key)
    
    super
  end
end

class StreamDSL
  def method_missing(key, *args)
    <<~HTML
      <turbo-stream action="#{key}" target="#{args[0]}">
        <template>
          #{args[1]}
        </template>
      </turbo-stream>
    HTML
  end
end

class SerbView
  include Serbea::Helpers

  attr_accessor :baz

  class InputField
    attr_reader :name

    def initialize(name, options = {})
      @name = name
      @options = options
    end

    def to_s
      str = "<input type=\"text\" name=\"#{@name}\" "
      
      @options.each do |k, v|
        if [true, false].include? v
          str << "#{k} " if v
        else
          str << "#{k}=\"#{Erubi.h v}\" "
        end
      end
      
      str << "/>"
    end
  end

  class Fields
    def input(name, options = {})
      InputField.new(name, options)
    end
  end

  def initialize(baz)
    @baz = baz
  end

  def da_value; '"Totally \'wild'; end
 
  def foo(value, extra_value, bar:)
    value + "(#{extra_value})" + bar.downcase
  end

  def finalize(value)
    "((#{value}))"
  end

  def pagedata=(data)
    @page = OpenStruct.new(data: data)
  end

  def page
    @page
  end

  def form(classname:)
    previous_buffer_state = @_erbout
    @_erbout = Serbea::OutputBuffer.new
    fields = Fields.new
    str = "<form class=\"#{classname}\">"
    str << yield(fields)
    str << "</form>"
    @_erbout = previous_buffer_state

    str
  end

  def form_with(model:, **kwargs)
    "<form model='#{model}'></form>"
  end

  def content_tag(tag_name, *attrs, &block)
    if block
      content = capture(&block)
    else
      content = attrs.first
      attrs = attrs[1..]
    end
    processed_attrs = ""
    attrs[0].each do |key, value|
      processed_attrs << " #{key}=\"#{value}\""
    end if attrs.present?

    "<#{tag_name}#{processed_attrs}>#{content}</#{tag_name}>"
  end

  def errors(input, errors = {})
    if errors && errors.key?(input.name)
      "<div class=\"error\">" + input.to_s + "</div>"
    else
      input
    end
  end

  def render(tmpl_name, variables = {}, &block)
    if (block)
      variables.merge!({content: capture(&block)})
    elsif !variables.key?(:content)
      variables.merge!({content: ""})
    end

    unless tmpl_name.is_a?(String)
      return "Component! < #{variables[:content]} >"
    end

    fake_tmpl = "aha! {{ content }} yes! cool {%= cool %}"
    
    tmpl = Tilt::SerbeaTemplate.new { fake_tmpl }

    tmpl.render(FakeComponentRenderer.new(variables))
  end

  def partial(partial_name, options = {})
    options.merge!(options[:locals]) if options[:locals]

    partial_segments = partial_name.split("/")
    partial_segments.last.sub!(%r!^!, "_")
    partial_name = partial_segments.join("/")

    Tilt::SerbeaTemplate.new(
      File.join(__dir__, "partials", "#{partial_name}.serb")
    ).render(self, options)
  end

  def turbo_frame_tag(tag, &block)
    "<!-- #{tag}: #{capture(&block)} -->"
  end

  def turbo_stream
    StreamDSL.new
  end
end


#simple_template = "Hi {{ 'there' }}"
#tmpl = Tilt::SerbeaTemplate.new { simple_template }

Serbea::TemplateEngine.front_matter_preamble = "self.pagedata = YAML.load"
Serbea::TemplateEngine.directive :form, ->(code, buffer) do
  model_name, space, params = code.lstrip.partition(%r(\s)m)
  model_name.chomp!(",")
  model_name = "#{model_name}," unless params.lstrip.start_with?("do", "{")

  buffer << "{%= form_with model: "
  buffer << model_name << " #{params}"
  buffer << " %}"
end

Serbea::TemplateEngine.directive :frame, ->(code, buffer) do
  buffer << "{%= turbo_frame_tag "
  buffer << code.strip.sub(/do$/, "")
  buffer << " do %}"
end

Serbea::TemplateEngine.directive :append, ->(code, buffer) do
  buffer << "{%= turbo_stream.append "
  buffer << code
  buffer << " %}"
end

Serbea::TemplateEngine.directive :_, ->(code, buffer) do
  buffer << "{%= content_tag "
  buffer << code
  buffer << " %}"
end
#Serbea::Pipeline.raise_on_missing_filters = true

tmpl = Tilt.new(File.join(__dir__, "template.serb"))

#puts "====="
#puts tmpl.instance_variable_get(:@engine).src
#puts "====="

baz = "LALA"

class ButtonComponent
  def initialize(options = {})
    #p options
  end
end

class LambdaTest
  def scope(name, func)
    "Name: #{name}, output: #{func.call(10)}"
  end
end

output = tmpl.render(SerbView.new(baz))

previous_output = File.read(File.join(__dir__, "test_output.txt"))

if output.strip != previous_output.strip
  File.write(File.join(__dir__, "bad_output.txt"), output)
  raise "Output does not match! Saved to bad_output.txt"
end

puts "\nYay! Test passed."
