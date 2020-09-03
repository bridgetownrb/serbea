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
