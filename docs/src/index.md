---
layout: home
---

### Serbea is the Ruby template engine you didn't realize you needed. Until now.
{:.no_toc}

**Serbea** combines the best ideas from "brace-style" template languages such as Liquid, Nunjucks, Twig, Jinja, Mustache, etc.—and applies them to the world of **ERB**. You can use Serbea in Rails applications, Bridgetown static sites, or pretty much any Ruby scenario you could imagine.

**Serbea**. Finally, something to crow(n) about. _Le roi est mort, vive le roi!_

<aside markdown="block">

==New in Serbea 2.0!== You can now add "pipeline operator" functionality to _any_ Ruby template or class! [Check out the documentation below.](#add-pipelines-to-any-ruby-templates)

</aside>

### Table of Contents
{:.no_toc}
* …
{:toc}

### Features and Syntax

{% raw %}

* **Real Ruby**. Like, for real.
* Supports every convention of ERB and builds upon it with new features (which is why it's "awesomer!").
* Filters! Frontmatter!! Pipeline operators!!! 🤩
* The filters accessible within Serbea templates are either traditional helpers (where the variable gets passed as the first argument) or _instance methods of the variable itself_. So you can build extremely expressive pipelines that take advantage of the code you already know and love.

  For example, in Rails you could write:
  
  ```serbea
  {{ "My Link" | sub: "Link", "Page" | link_to: route_path }}
  ```

* The `Serbea::Pipeline.exec` method lets you pass a pipeline template in, along with an optional input value or included helpers module, and you'll get the output as a object of any type (not converted to a string like in traditional templates). 

  For example:

  ```serbea
  Serbea::Pipeline.exec %( arr |> map: ->(i) { i * 10 } ), arr: [1,2,3]
  ```

  will return:

  ```serbea
  [10, 20, 30]
  ```

* Alternatively, ==now in Serbea 2.0== you can execute pipelines in plain ol' Ruby within any template or class! [See documentation below.](#add-pipelines-to-any-ruby-templates)
* Serbea will HTML autoescape variables by default within pipeline (`{{ }}`) tags. Use the `safe` / `raw` or `escape` / `h` filters to control escaping on output.
* Directives apply handy shortcuts that modify the template at the syntax level before processing through Ruby.

  `{%@ %}` is a shortcut for rendering either string-named partials (`render "tmpl"`) or object instances (`render MyComponent.new`). And in Rails, you can use Turbo Stream directives for extremely concise templates:

  ```serbea
  {%@remove "timeline-read-more" %}
  {%@append "timeline" do %}
    {%@ partial: "posts", formats: [:html] %}
  {% end %}
  ```
* Built-in frontmatter support. Now you can access the variables written into a top YAML block within your templates. In any Rails view, including layouts, you'll have access to the `@frontmatter` ivar which is a merged `HashWithDotAccess::Hash` with data from any part of the view tree (partials, pages, layout).

  For example, you could put `<title>{{ @frontmatter.title }}</title>` in your head partial, and then each page could define `title` frontmatter individually. You can even use Ruby string interpolation within the YAML so titles and other metadata can come from `t` language helpers.
* Define macros/helpers which can be imported and used within Serbea templates.

  ```serb
  <!-- _macros.serb -->
  {% macro :greet do |name:| %}
    {{ name }}, my old friend!
  {% end %}

  <!-- tmpl.serb -->
  {% import "macros" %}

  Hello {{ greet(name: "darkness") }}
  ```

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

Use `helper` (alias `macro`) to create ad-hoc filters:

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

{:style="text-align:center"}
_(For Rails and Bridgetown scenarios, see below.)_

Simply add the Serbea gem to your `Gemfile`:

```
bundle add serbea
```

or install standalone:

```
gem install serbea
```

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

You'll likely want to bind to a dedicated view object instead of `self` as in the example above, since that view object can include the Serbea helpers without fear of any collision with existing object methods in your codebase.

Serbea helpers include `pipeline` which faciliates the `{{ }}` template syntax, `capture`, `helper`, `safe`, `escape`, and `assign_to`.
{% endraw %}

### Bridgetown Support

If you're using [Bridgetown 1.0](https://www.bridgetownrb.com), Serbea is automatically included! [See Serbea-specific documentation here.](https://www.bridgetownrb.com/docs/template-engines/erb-and-beyond#serbea)

Serbea is an excellent upgrade from Liquid as the syntax initially looks familar, yet it enbles the full power of real Ruby in your templates.

Out of the box, you can name pages and partials with a `.serb` extension. But for even more flexibility, you can add `template_engine: serbea` to your `bridgetown.config.yml` configuration. This will default all pages and documents to Serbea unless you specifically use front matter to choose a different template engine (or use an extension such as `.liquid` or `.erb`).

Here's an abreviated example of what the Post layout template looks like on the [Fullstack Ruby](https://www.fullstackruby.dev) blog:

{% raw %}
```serb
---
layout: bulmatown/post
---

<div class="content-column">{%= yield %}</div>

{{ liquid_render "subscribe" }}

{% if page.data.image_credit %}
  <p class="mt-6 is-size-7 has-text-centered">
    <em>Banner image by <a href="{{ page.data.image_credit.url | safe }}">
      {{ page.data.image_credit.label }}
    </a></em>
  </p>
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

### Rails Support

To use in Rails, run:

`bundle add serbea-rails`

Serbea fully supports Rails (tested with Rails 6), and even includes special directives for Turbo Streams as highlighted above.

Simply use the `.serb` extension wherever you would use `.erb` normally. You can freely mix 'n' match Serbea templates with other template engines, so for instance `index.html.erb` and `show.html.serb` can live side-by-side.

**Note:** if you use a Serbea template as a _layout_, you may encounter some subtle rendering issues with ERB page templates that use the layout. It is recommended you use Serbea for layouts only if you intend to standardize on Serbea for your application.

**Upgrade your helpers!** While you can use the same kind of syntax for helpers you may be accustomed to in ERB, using the pipeline syntax can be far more enjoyable and better express intent. For example, instead of confusing nested method calls like this:

{% raw %}
```erb
Here's a <%= link_to(highlight("  link for you  ".strip.titleize, "you"), other_page_path) %>
```

You could instead write this:

```serb
Here's a {{ "  link for you  " | strip | titleize | highlight: "you" | link_to: other_page_path }}
```

which is _far_ easier to parse visually and less likely to cause bugs due to nesting errors.

**Stay Safe!** In pipelines, Serbea uses the same safe escaping logic you've experienced with ERB. So if you were to put `{{ "<p>Aha!</p>" }}` in a template, you don't get an HTML paragraph, you get the literal characters of the p tags. You would have to use the `safe` (aliased `raw`) filter in order to get working HTML output. _However_, that is NOT the case with expressions. `{%= "<p>Bingo!</p>" %}` outputs that text verbatim and you get a valid HTML paragraph. So use expressions sparingly and only in cases where you know the values have already been cleansed (e.g., rendering partials or components, using form helpers, yielding in layouts, etc.). Alternatively, you can use the `escape` (aliased `h`) helper: `{%= escape "<p>Bingo!</p>" %}`.

{% endraw %}

### Add Pipelines to Any Ruby Templates

New in Serbea 2.0, you can use a pipeline operator (`|`) within a `pipe` block to construct a series of expressions which continually operate on the latest state of the base value.

All you have to do is include `Serbea::Pipeline::Helper` inside of any Ruby class or template environment (aka ERB).

Here's a simple example:

```ruby
class PipelineExample
  include Serbea::Pipeline::Helper

  def output
    pipe("Hello world") { upcase | split(" ") | test_join(", ") }
  end

  def test_join(input, delimeter)
    input.join(delimeter)
  end
end

PipelineExample.new.output.value # => HELLO, WORLD
```

As you can see, a number of interesting things are happening here. First, we're kicking off the pipeline using a string value. This then lets us access the string's `upcase` and `split` methods. Once the string has become an array, we pipe that into our custom `test_join` method where we can call the array value's `join` method to convert it back to a string. Finally, we return the output value of the pipeline.

Like in native Serbea template pipelines, every expression in the pipeline will either call a method on the value itself, or a filter-style method that's available within the calling object. As you might expect in, say, an ERB template, all of the helpers are available as pipeline filters. In Rails, for example:

```erb
Link: <%= pipe("nav.page_link") { t | link_to(my_page_path) } %>
```

This is roughly equivalent to:

```erb
Link: <%= link_to(t("nav.page_link"), my_page_path) %>
```

The length of the pipe code is slightly longer, but it's easier to follow the order of operations:

1. First, you start with the translation key.
2. Second, you translate that into official content.
3. Third, you pass that content to `link_to` along with a URL helper.

There are all sorts of uses for a pipeline, not just in templates. You could construct an entire data flow with many transformation steps. And because the pipeline operator `|` is actually optional when using a multi-line block, you can just write a series of simple Ruby statements:

```ruby
def transform(input_value)
  pipe input_value do
    transform_this_way
    transform_that_way
    add_more_data(more_data)
    convert_to_whatever # maybe this is called on the value object itself
    value ->{ AnotherClass.operate_on_value _1 } # return a new value from outside processing
    now_we_are_done!
  end
end

def transform_this_way(input) = ...
def transform_that_way(input) = ...
def add_more_data(input, data) = ...
def now_we_are_done!(input) = ...

transform([1,2,3])
```

### How Pipelines Work Under the Hood

In Serbea templates, code which looks like this:

{% raw %}
```serb
{{ data | method_call | some_filter: 123 }}
```
{% endraw %}

gets translated to this:

```ruby
pipeline(data).filter(:method_call).filter(:some_filter, 123)
```

In plain Ruby, `method_missing` is used to proxy method calls along to `filter`, so:

```ruby
pipe(data) { method_call | some_filter(123) }
```

is equivalent to:

```ruby
pipe(data) { filter(:method_call); filter(:some_filter, 123) }
```

Pipelines "inherit" their calling context by using Ruby's `binding` feature. That's how they know how to call the methods which are available within the caller.

Another interesting facet of Serbea pipelines is that they're forgiving by default. If a filter can't be found (either there's no method available to call the object itself nor is there a separate helper method), it will log a warning to STDERR and continue on. This is to make the syntax feel a bit more like HTML and CSS where you can make a mistake or encounter an unexpected error condition yet not crash the entire application.

If you do want to crash your entire application (😜), you can set the configuration option: `Serbea::Pipeline.raise_on_missing_filters = true`. This will raise a `Serbea::FilterMissing` error if a filter can't be found.
