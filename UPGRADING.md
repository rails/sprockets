# Guide to upgrading from Sprockets 2.x to 3.x

Even though its a major release, Sprockets 3.x should be fairly API compatible
with 2.x unless explicitly note in the CHANGELOG. For the most part, the
application facing APIs have remained the same with the majority of the changes
at the extension layer. So you shouldn't have to change much application code,
but you should verify that all the sprockets extension gems you are using are
compatible with 3.x.

## Application Changes

### Preference for asset manifest and links

Previously, Sprockets had no idea what files you wanted to statically compile
and how they related to each other. Now assets have the concept of referencing
each with "links". This provides a composable way for assets subresources to be
declared.

``` css
/* homepage.css */
.logo {
  background: url("logo.png")
}
```

Typically you have these subresource relations in css files to other images.
You'd have to tell Sprockets to compile both the css and image.

But now when you use any of the asset helpers in ERB or SCSS, a link
relationship to created between the two assets.

``` css
.logo {
  background: url(<%= asset_url("logo.png") %>)
}
```

Its understood that whenever `homepage.css` is compiled, you'll need `logo.png`
too.

Most of the time you won't have to think up declaring links, helpers will do
that for you. But there are programmatic APIs for setting up links if you're
doing something custom.

``` css
/* A comment directive or erb call can we used to declare a link relationship */
/*= link logo.png */
<%= link_asset "logo.png" %>
.logo {}
```

Since links are composable, you can use them to define a single "manifest" file
that links to ever asset you need in production.

``` js
// app/assets/manifest.js
//
// JS bundles
//= link ./javascripts/standalone-jquery.js
//= link ./javascripts/application.js
//= link ./javascripts/settings.js
//
// CSS bundles
//= link ./stylesheets/application.css
//= link ./stylesheets/settings.css
//
// Pull in all app/assets/images/ since app/views may link to them
//= link_tree ./images
```

Then compiling `manifest` will ensure all the subresources are compiled as well.

``` ruby
config.assets.precompile = ["manifest.js"]
```

### Prefer just `foo.coffee` and `foo.scss`

Instead of the longer `foo.js.coffee` and `foo.css.scss`. This shorthand works in
2.x but is preferred going forward.

### Rev `version` less often

Many load path changing caching bugs have been fixed and processors can now
partipate in asset cache invalidation. So when you upgrade CoffeeScript, it will
automatically bust old changes. You'll need to be sure you're running the latest
versions of any Sprockets extensions so they opt into these new cache APIs.

### Removed `//= include` directive

You can replace this with ERB usage `<%= environment.find_asset("foo") %>`. This
will also allow you to put the contents anywhere you want in the file.

## Extension Changes

If you're a Sprockets plugin author you should definitely take some time to
migrate to the new processor API. You can relax for now since 3.x will still
support the old Tilt interface. 4.x will be the hard break away. Hopefully our
existing extensions still work on both 2.x and 3.x (unless you're using private
apis or monkey patching things).

So whats wrong with Tilt, why bother?

It was probably a good decision at the time, but we've out grown the constraints
of the Tilt template interface. After all, it was primarily designed for dynamic
HTML template engines, not assets like JS and CSS or binary assets like images.
Sprockets would like to have other metadata passed between processors besides
simple Strings. Passing source maps was one of the primary motivators.

Instead of a Tilt template interface, we now have a uniform Processor interface
across every part of the pipeline.

Similar to Rack, a processor is a any "callable" (an object that responds to
`call`). This maybe a simple Proc or a full class that defines a `def
self.call(input)` method. The `call` method accepts an `input` Hash and returns
a Hash of metadata.

If you just care about modifying the input data, the simplest processor looks
like

``` ruby
proc do |input|
  # Take input data, remove all semicolons and return a string
  input[:data].gsub(";", "")
end
```

A `proc` works well for quick user defined processors, but you might want to use
a full class for your extension.

``` ruby
class MyProcessor
  def initialize(options = {})
    @options = options
  end

  def call(input)
  end
end

# A initializer pattern can allow users to configure application specific
# options for your processor
MyProcessor.new(style: :minimal)
```

`call(input)` is the only required method to implement, you can also provide a
`cache_key` method. This allows the processor to bust asset caches after a
library upgrade or configuration changes.

``` ruby
class MyProcessor
  def initialize(options = {})
    @options = options
  end

  def cache_key
    ['3', @options]
  end

  def call(input)
  end
end
```

`cache_key` may return any simple JSON serializable value to use to
differentiate caches. This may just be a static version identifier you change
every gem release or configuration options declared on setup.

Heres a pretty standard processor boilerplate thats used internally for
Sprockets.

``` ruby
class MyProcessor
  VERSION = '3'

  def self.instance
    @instance ||= new
  end

  def self.call(input)
    instance.call(input)
  end

  def self.cache_key
    instance.cache_key
  end

  attr_reader :cache_key

  def initialize(options = {})
    @cache_key = [self.class.name, VERSION, options].freeze
  end

  def call(input)
    # process input
  end
end
```
