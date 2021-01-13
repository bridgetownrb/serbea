---
layout: home
---

### Serbea is the Ruby template engine you didn't realize you needed. Until now.

**Serbea** combines the best ideas from "brace-style" template languages such as Liquid, Nunjucks, Twig, Jinja, Mustache, etc.—and applies them to the world of **ERB**. You can use Serbea in Rails applications, Bridgetown static sites, or pretty much any Ruby scenario you could imagine.

**Serbea**. Finally, something to crow(n) about. _Le roi est mort, vive le roi!_

### Features and Syntax

{% raw %}

* **Real Ruby**. Like, for real.
* Supports every convention of ERB and builds upon it with new features (which is why it's "awesomer!").
* Filters! Frontmatter!! Pipeline operators!!! 🤩
* The filters accessible within Serbea templates are either traditional helpers (where the variable gets passed as the first argument) or _instance methods of the variable itself_. So you can build extremely expressive pipelines that take advantage of the code you already know and love.

  For example, in Rails you could write: `{{ "My Link" | sub: "Link", "Page" | link_to: route_path }}`.
* The `Serbea::Pipeline.exec` method lets you pass a pipeline template in, along with an optional input value or included helpers module, and you'll get the output as a object of any type (not converted to a string like in traditional templates). 

  For example:
  
  `Serbea::Pipeline.exec %( arr |> map: ->(i) { i * 10 } ), arr: [1,2,3]`
  
  will return:
  
  `[10, 20, 30]`

* Serbea will HTML autoescape variables by default within pipeline (`{{ }}`) tags. Use the `safe` / `raw` or `escape` / `h` filters to control escaping on output.
* Directives apply handy shortcuts that modify the template at the syntax level before processing through Ruby.

  `{%@ %}` is a shortcut for rendering either string-named partials (`render "tmpl"`) or object instances (`render MyComponent.new`). And in Rails, you can use new Turbo Stream directives for extremely consise templates:

  ```serb
  {%@remove "timeline-read-more" %}
  {%@append "timeline" do %}
    {%@ partial: "posts", formats: [:html] %}
  {%@ %}
  ```
* Built-in frontmatter support. Now you can access the variables written into a top YAML block within your templates. In any Rails view, including layouts, you'll have access to the `@frontmatter` ivar which is a merged `HashWithDotAccess::Hash` with data from any part of the view tree (partials, pages, layout).

  For example, you could put `<title>{{ @frontmatter.title }}</title>` in your head partial, and then each page could define `title` frontmatter individually. You can even use Ruby string interpolation within the YAML so titles and other metadata can come from `t` language helpers.


{% endraw %}

### What Serbea Looks Like

{% raw %}

```serb
<!-- example.serb -->

{% wow = capture do %}
  This is {{ "amazing" + "!" | upcase }}
{% end %}

{% wow = wow.each_char.reduce("") do |newstr, c|
    newstr += " #{c}"
   end.strip %}

{{ wow | prepend: "OMG! " }}
```

Serbea lets us define helpers inside templates directly:

```serb
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

Forms, partials, etc. No sweat! 

```serb
{%= form classname: "checkout" do |f| %}
  {{ f.input :first_name, required: true | errors: error_messages }}
{% end %}

{%= render "box" do %}
  This is **dope!**
  {%= render "card", title: "Nifty!" do %}
    So great.
  {% end %}
{% end %}
```

Let's simplify that using the render directive!

```serb
{%@ "box" do %}
  This is **dope!**
  {%@ "card", title: "Nifty!" do %}
    So great.
  {% end %}
{% end %}
```

Works with ViewComponent! And we can use the render directive!

```serb
{%@ Theme::DropdownComponent name: "banner", label: "Banners" do |dropdown| %}
  {% RegistryTheme::BANNERS.each do |banner| %}
    {% dropdown.slot(:item, value: banner) do %}
      <img src="{{ banner | parameterize: separator: "_" | prepend: "/themes/" | append: ".jpg" }}">
      <strong>{{ banner }}</strong>
    {% end %}
  {% end %}
{% end %}
```

The `|` and `|>` pipeline operators are equivalent, so you can write like this if you want!

```serb
{{
  [1,2,3] |>
    map: -> i { i * 10 }
  |>
    filter: -> i do
      i > 15 # works fine with multiline blocks
    end
  |>
    assign_to: :array_length
}}

Array length: {{ @array_length.length }}
```
{% endraw %}

{{
  [1,2,3] |>
    map: -> i { i * 10 }
  |>
    filter: -> i do
      i > 15 # works fine with multiline blocks
    end
  |>
    assign_to: :array_length
}}

The answer of course is: **{{ @array_length.length }}**
