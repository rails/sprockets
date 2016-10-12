# Guide to upgrading from Sprockets 2.x to 3.x

Even though its a major release, Sprockets 3.x should be fairly API compatible
with 2.x unless explicitly noted in the CHANGELOG. For the most part, the
application facing APIs have remained the same with the majority of the changes
at the extension layer. So you shouldn't have to change much application code,
but you should verify that all the sprockets extension gems you are using are
compatible with 3.x.

## Application Changes

### public/assets/manifest-abc123.json location

JSON manifests are now written out to `.sprockets-manifest-abc123.json` to
prevent collisions with assets actually called `manifest`. If any old manifests
exists they will automatically be renamed. Just note if you were depending on
the `manifests-abc123.json` name in a deployment related task, you'll see this
new file showing up.

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
/* A comment directive or erb call can be used to declare a link relationship */
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

**Caution** Unlike `require` directives, links should have an explicit content
type or file extension. When using `link_directory` or `link_tree` prefer
setting a format as well.

``` js
// A mime type or file extension can be given as a second parameter to
// link_directory or link_tree
//
//= link_directory ./scripts .js
//= link_tree ./styles text/css
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

### Processor Interface

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

### Transformers

Sprockets 2.x always had a one to one mapping between source file on disk
(app/assets/javascripts/application.coffee.rb) to compiled artifact
(public/assets/application.js). This has prevented the ability to compile assets
to multiple targets such as image conversations from logo.svg to logo.png,
logo.jpg, logo.gif, etc.

Supporting variants will definitely make the processor chain more powerful, but
it means moving away from some previous patterns. For an example, we can only
simply map over all assets under a directory like app/assets since a single file
may have multiple representations depending on the requested content type.

To support transformers, two APIs have been added.

First, the ability to request a variant of an asset for a content type.

``` ruby
# Find any source asset named "logo" that can be transformed into "image/png"
env.find_asset("logo", accept: "image/png")

# or using the more common extension format now means the same
env.find_asset("logo.png")
```

Second, a processor API for describing transformation types.

``` ruby
Sprockets.register_transformer 'image/svg+xml', 'image/png', SVG2PNGProcessor
Sprockets.register_transformer 'image/svg+xml', 'image/gif', SVG2GIFProcessor
```

Even if you don't need to support multiple content types, transformers can
replace traditional engines.

``` ruby
# Register a content type for file extension, its okay if its made up
register_mime_type 'text/coffeescript', extensions: ['.coffee']
register_transformer 'text/coffeescript', 'application/javascript', CoffeeScriptProcessor
```

Some important differences from previous engines.

**We can request the file in its original content type.**

``` ruby
# Return the file as is
env.find_asset("foo.coffee").source
```

Its important we can serve the original source file to the browser if source
maps are being used.

**Preprocesors run for the source content type, not the destination**

``` ruby
register_preprocessor 'text/coffeescript', LintCoffeeScript
register_postprocessor 'application/javascript', FormatJavaScript
```

Before converting a coffeescript file to JS, we first run any coffeescript
preprocessors, convert it to JS, then run the postprocessor. Because we have a
before and after content type distinction, theres not much use for pre vs post
processors. Once the transition to transformers is complete, prefer just using
`register_preprocessor` with the correct content type.

**Transformers may bind to multi-extnames**

``` ruby
register_mime_type 'application/javascript+module', extensions: ['.module.js']
register_mime_type 'text/html+ruby', extensions: ['.html.erb']
register_mime_type 'text/yaml+manifest', extensions: ['.manifest.yml']
```

Whatever special extname you pick, it doesn't necessarily have to be at the end
of the file. Prefer having an extname at the end that plays nice if your
editor's syntax highlighting.

However, this requires you whitelist all the compatible extension combinations.
Theres no free form chaining. This turned out to be a less useful feature. It
meant `foo.js.coffee.erb.haml.jst.eco.sass` was a legal processor chain, but
pretty useless.


### Pipeline overview

* Run preprocessors for source content type (`text/coffeescript`)
* Run legacy engines defined by file extensions (.erb)
* Run postprocessors for source content type (`text/coffeescript`)
* Run transformer from source to destination content type (coffee->js)
* Run preprocessors for destination content type (`application/javascript`)
* Run postprocessors for destination content type (`application/javascript`)
* Concatenate "required" files
* Run bundle processors

With engines being phased out, we can collapse the pre and post processor
chains. But that still leaves the "bundle" step as a special thing. I haven't
quite figured out how to it more unified. Let me know if you have any ideas.
