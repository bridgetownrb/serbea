require "bundler"
require "serbea"

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

  def form(classname:)
    previous_buffer_state = @_erbout
    @_erbout = +""
    fields = Fields.new
    str = "<form class=\"#{classname}\">"
    str << yield(fields)
    str << "</form>"
    @_erbout = previous_buffer_state

    str
  end

  def errors(input, errors = {})
    if errors && errors.key?(input.name)
      "<div class=\"error\">" + input.to_s + "</div>"
    else
      input
    end
  end

  def render(tmpl_name, variables = {}, &block)
    previous_buffer_state = @_erbout
    @_erbout = +""
    if (block)
      variables.merge!({content: yield})
    elsif !variables.key?(:content)
      variables.merge!({content: ""})
    end
    @_erbout = previous_buffer_state

    fake_tmpl = "aha! {{ content }} yes! cool {%= cool %}"
    fake_tmpl += "{% if defined? blah %}wee!{% end %}"
    
    tmpl = Tilt::SerbeaTemplate.new { fake_tmpl }

    tmpl.render(Serbea::ComponentRenderer.new(variables))
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
  alias_method :import, :partial
end


simple_template = "Hi {{ 'there' }}"


#tmpl = Tilt::SerbeaTemplate.new { simple_template }

tmpl = Tilt.new("template.serb")

#puts "====="
#puts tmpl.instance_variable_get(:@engine).src
#puts "====="

baz = "LALA"

output = tmpl.render(SerbView.new(baz))

puts output