# Serbea: Similar to ERB, Except Awesomer

Serbea is the love child of Liquid, Nunjucks, and ERB.

Make of that what you will.

Coming soon…

```ruby
# example.serb

{% wow = capture do %}
  This is {{ "amazing" + "!" | upcase }}
{% end.each_char.reduce("") do |newstr, c|
    newstr += " #{c}"
   end.strip %}

{{ wow | prepend: "OMG! " }}
```

```ruby
<p>
  {%
    helper :multiply_array do |input, multiply_by = 2|
      input.map do |i|
        i.to_i * multiply_by
      end
    end
  %}

  Multiply! {{ [1,3,6, "9"] | multiply_array: 10 }}
</p>
```

```ruby
{%>= form classname: "checkout" do |f| %}
  {{ f.input :first_name, required: true | errors: error_messages }}
{%|> end %}
```

```ruby
{%>= render "box" do %}
  This is **dope!**
  {%>= render "card", title: "Nifty!" do %}
    So great.
  {%|> end %}
{%|> end %}
```
