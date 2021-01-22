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

### Installation and Usage

Simply add the Serbea gem to your `Gemfile`:

```
bundle add serbea
```

or install standalone:

```
gem install serbea
```

If you're using [Bridgetown](https://www.bridgetownrb.com), make sure it's included in the `bridgetown_plugins` group.

Serbea templates are typically saved using a `.serb` extension. If you use VS Code as your editor, there is a [VS Code extension](https://marketplace.visualstudio.com/items?itemName=whitefusion.serbea) to enable Serbea syntax highlighting as well as palette commands to convert selected ERB syntax to Serbea.

To convert Serbea code in a basic Ruby script, all you have to do is require the Serbea gem, include the necessary helpers module, and use the Tilt interface to load and render the template. Example:

{% raw %}
```ruby
require "serbea"
include Serbea::Helpers

tmpl = Tilt::SerbeaTemplate.new { "Hello {{ world | append: '!' }}" }
tmpl.render(self, world: "World")

# Hello World!
```
{% endraw %}

You'll likely want to bind to a dedicated view object instead of `self` as in the example above, since that view object can include the Serbea helpers without fear of any collision with existing object methods in your codebase.

Serbea helpers include `pipeline` which faciliates the `{{ }}` template syntax, `capture`, `helper`, `safe`, `escape`, and `assign_to`.

### Rails Support

Serbea fully supports Rails (tested with Rails 6), and even includes special directives for Turbo Streams as highlighted above.

Simply use the `.serb` extension wherever you would use `.erb` normally. You can freely mix 'n' match Serbea templates with other template engines, so for instance `index.html.erb` and `show.html.serb` can live side-by-side.

**Note:** if you use a Serbea template as a _layout_, you may encounter some subtle rendering issues with ERB page templates that use the layout. It is recommended you use Serbea for layouts only if you intend to standardize on Serbea for your application.

### Bridgetown Support

Serbea fully supports [Bridgetown](https://www.bridgetownrb.com). In fact, Serbea is an excellent upgrade from Liquid as the syntax initially looks familar, yet it enbles the full power of real Ruby in your templates.

Out of the box, you can name pages and partials with a `.serb` extension. But for even more flexibility, you can add `template_engine: serbea` to your `bridgetown.config.yml` configuration. This will default all pages and documents to Serbea unless you specifically use front matter to choose a different template engine (or use an extension such as `.liquid` or `.erb`).

Here's an abreviated example of what the Post layout template looks like on the [RUBY3.dev](https://www.ruby3.dev) blog:

{% raw %}
```serb
---
layout: bulmatown/post
---

<div class="content-column">{%= yield %}</div>

{{ liquid_render "subscribe" }}

{% if page.data.image_credit %}
  <p class="mt-6 is-size-7 has-text-centered"><em>Banner image by <a href="{{ page.data.image_credit.url | safe }}">{{ page.data.image_credit.label }}</a></em></p>
{% end %}

{% posts = page.related_posts[0...2] %}
{{ liquid_render "bulmatown/collection", collection: posts, metadata: site.metadata }}

{% if page.related_posts.size > 2 %}
  <a href="/articles">Read More Articles</a>
{% end %}

{%= markdownify do %}
  {{ liquid_render "sponsor" }}
{% end %}
```
{% endraw %}
