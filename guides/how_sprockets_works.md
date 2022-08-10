# Introduction

> This document is based off of a transcript from [RailsConf 2016 - How Sprockets works by Rafael França](https://www.youtube.com/watch?v=CzFFYelG7WY). It's been edited in an attempt to make sense outside the context of a conference talk. [Rafael](https://github.com/rafaelfranca) is amazing and does great work with Sprockets and Rails.

Rails is presented in a lot of different ways, it's not just the Rails gem but there are a lot of different components, for example: [Action View](https://github.com/rails/rails/tree/master/actionview), [Spring](https://github.com/rails/spring), [jquery-ujs](https://github.com/rails/jquery-ujs), [Turbolinks](https://github.com/turbolinks/turbolinks-classic), [Sprockets](https://github.com/rails/sprockets).

You can see that the Rails framework involves most aspects of your computer and operating system. You have things on the process level like Spring, and also things running in the browser like jquery-ujs and Turbolinks.

This goal of this document is to present something that is not well-known. That is, how the asset pipeline of Rails works right now [ca. 2016]. We will talk about why you need the asset pipeline, which gems are responsible for it, how it works in a Rails application, and how to extend the asset pipeline yourself.

First, why do we need an asset pipeline? Before we had the asset pipeline in Rails – introduced in Rails 3.1 – we had a question: "Where should I put my assets?". We did not have any established convention for how to handle client-side code in Rails applications. So we typically had to put all of our assets in the `public` folder. Usually we ended up with a lot of files and it became difficult to know if they are being used or not.

Rails is about convention over configuration, so that was not something that we should have done with our client-side code. We also have another problem: we had to make some trade-offs between code organization and performance. Browsers had limitations; the Internet was too slow. There are trade offs to make. For example should we create many small self-contained files, or should we do fewer requests for assets in our applications? Initializing an HTTP connection to download an asset is expensive, yet working inside of one really large file is also difficult.

Should we write legible code? Or should we transmit fewer bytes to the clients? There were some technologies that were being used in that time, but could not be used easily in Rails applications. Technologies like [CoffeeScript](https://coffeescript.org/), [SASS](https://sass-lang.com/), and [ECMAScript 6](http://es6-features.org/). To solve these problems, the asset pipeline was created.

But how does the asset pipeline work in Rails? Right now, we have some conventions for our client-side code. So our assets live in the `app/assets` folder, and there are also `lib/assets` and `vendor/assets` folders. Assets are compiled on-the-fly in development and need to be precompiled in production. We also have asset fingerprinting so the digest of the asset content becomes part of the filename itself to provide automatic cache busting.

The asset pipeline is built from a collection of gems:

- [sprockets](https://rubygems.org/gems/sprockets/versions/3.5.2)
- [sprockets-rails](https://rubygems.org/gems/sprockets-rails)
- [sass-rails](https://rubygems.org/gems/sass-rails)
- [execjs](https://rubygems.org/gems/execjs)
- [coffee-rails](https://rubygems.org/gems/coffee-rails)

We will go through each gem and talk about how they work. The first gem that I'm going to talk about is Sprockets. It's the gem that makes it possible to compile and serve all assets. Sprockets defines a processor pipeline so you can extend the way your assets are processed.

## Sprockets

Sprockets has some key components that are:

- processors
- transformers
- compressors
- directives
- environments
- manifest
- pipelines

### Processors

The processors are the most important components in Sprockets. All the functionality inside of Sprockets is implemented by a processor. This is similar to how Railties is also a Rails engine. The interface for a processor is any `call`-able object that accepts an input hash and returns a hash of both data and optional metadata.

Example of a minimal Ruby sprockets processor that is just a lambda expression (which is `call`able):

```ruby
-> (input) {
  data = input[:data].gsub(';', '')
  { data: data }
}
```

This is a minimal yet valid Sprockets processor and can be successfully called. It's doing something that is simple and easy to understand, which is just removing semicolons from the end of each line of the input. It takes a Hash as input that has some special keys that we will talk about later. It also returns a hash with specific keys, including `data` which contains the result of the processor running on the input.

The input hash has these keys by default:

- `:data` - The string contents of the asset
- `:environment` - The current `Sprockets::Environment` instance
- `:cache` - The `Sprockets::Cache` instance
- `:uri` - The asset URI
- `:source_path` - The full path to original file
- `:load_path` - The current load path for the file
- `:name` - The logical name of the file
- `:content_type` - The MIME type of the output asset
- `:metadata` - The Hash of processor metadata

The return hash has these keys:

- `:data` - Replaces the assets `input[:data]` for the next processor in the chain
- `:required` - A Set of String asset URIs that `Bundle` processor should concatenate together
- `:stubbed` - A Set of String asset URIs that will be omitted from the `:required` set
- `:links` - A Set of String asset URIs that should be compiled along with the assets
- `:dependencies` - A Set of String cache URIs that should be monitored for caching
- `:map` - An Array of source maps for the assets
- `:charset` - The MIME charset for an asset

As we will see later, the `:required` is really interesting. Each dependency from your asset files will be stored in this field.

There are a lot of interesting built-in processors including:

- `BabelProcessor`
- `CoffeScriptProcessor`
- `SassProcessor`
- `BundlerProcessor`

`BundlerProcessor` is used to run concatenated assets rather than individual files.

To register a processor in Sprockets, we use this syntax:

```ruby
register_bundle_processor 'application/javascript', Bundle
register_bundle_processor 'text/css', Bundle
```

We are saying that for any file with MIME type `application/javascript`, we are using the `Bundle` processor to take care of these files and concatenating them in the same file. So the `Bundle` processor takes a single file asset and prepends all the `required` URIs in the contents.

### Transformers

A transformer is a processor that converts a file from one format to another format. One of the examples is the `CoffeeScript` transformer that takes a `CoffeeScript` file and returns a JavaScript file.

```ruby
register_transformer 'text/coffescript', 'application/javascript', CoffeScriptProcessor
```

The implementation of these processors is really simple as we can see below:

```ruby
module CoffeScriptProcessor

  def self.call(input)
    data = input[:data]

     js, map = input[:cache].fetch([self.cache_key, data]) do
       result = CoffeScript.compile(data, sourceMap: true, sourceFiles: [input[:source_path]])
       [result['js'], decode_source_maps(result['v3SourceMap'])]
     end

     map = SourceMapUtils.combine_source_maps(input[:metadata][:map]), map)
     { data: js, map: map }
  end

end
```

We can see that it's a `call`-able object that takes an input and [passes it] through the `CoffeeScript` compiler and returns the result of this operation under the `data` key in the returned hash.

### Compressors

Compressors are a special kind of bundle processor because it runs on the concatenated file. You register a compressor using following syntax:

```ruby
register_compressor 'application/javascript', :uglify, UglifierCompressor
```

The main difference between the compressor and the bundle processor is compressors are used differently and you can have only one compressor per MIME type. Sprockets uses a special syntax to enable compressors. You can, for instance, compress any JavaScript file using this syntax:

```ruby
env.js_compressor = :uglify
```

### Directives

I'm sure you all have seen directives before because they are just special comments that declare your bundlers and their dependencies. This, for instance, is important for the `application.js` file that is generated by a new Rails application.

```js
// app/assets/javascripts/application.js
//= require jquery
//= require jquery-ui
//= require users
//= require_tree .
```

It's telling us that to generate this `application.js` file, we have to require these three files – `jquery.js`, `jquery-ui.js`, and `users.js` – including all the files inside the same directory of the `application.js` – which is `app/assets/javascripts`. Another special kind of directive that we have in Sprockets version 3 are the precompile lists wherein you are telling Sprockets to precompile these two files in production.

```ruby
Rails.application.config.assets.precompile << %w(application.js application.css)
```

Sprockets has special support for `Procs` on the precompilation. Before, in Sprockets version 3, we had this code that is telling us to precompile all the known JavaScript and stylesheet files in the app directory.

```ruby
LOOSE_APP_ASSETS = lambda do |logical_path, filename|
  filename.start_with?(::Rails.root.join('app/assets').to_s) &&
    !['.js', '.css', ''].include?(File.extname(logical_path))
end

config.assets.precompile = [LOOSE_APP_ASSETS, /(?:\/|\\|\A)application\.(.css|js)$/]
```

 As you can see, the code above is not easy to understand, so in Sprockets version 4, we have a new syntax for that shown below:

```js
// app/assets/config/manifest.js
//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css
//= link my_engine

// my_engine/app/assets/config/my_engine.js
//= link_tree ../images/bootstrap
```

It's called the link directive, so it's easier to understand what's going on there. You can actually see that all the images in the image directory is going to be precompiled just as the JavaScript and the style sheets do. One can use this directive to compose new libraries. I have that link to my engine that's also defining its own manifest file. It's now easy to understand and to compose. Not that we are going to remove the precompile list, but these new directives are there to help to build the precompile list. We have all these directives by default in Sprockets and later we will explain how you can extend the directives to create your own.

### Environment

Another component of Sprockets is the environment, and that is actually where your code runs. The environment has methods to retrieve and serve assets, change the load path, and register processors. When you're doing web requests for your asset file, what is going on is that the Sprockets environment is running and it's trying to find that specific file and send it back to you.

```ruby
environment = Sprockets::Environment.new
environment.find_assets('application.js')
```

The environment is also where you call all those methods that were discussed before, where you can register processors, compressors, and so on. As a part of the environment, we have the manifest that is just a log of the contents of all your precompiled assets in a directory and it is used to do fast lookups without having to actually compile the asset code.

```ruby
environment = Sprockets::Environment.new
Environment.register_transformer 'image/svg+xml', 'image/svg', SVGTransformer.new
```

The object below is really simple. It points the asset path to the fingerprinted version that's generated by Sprockets.

```ruby
javascript_include_tag 'application'
#<script src="/assets/application.debug-ddbd4593b22ac054471df143715c8ce65ef84938965c7db19d8a322950ec65b6.js">
#</script>
```

So, when one writes something like `javascript_include_tag 'application'`, what's going on is that Sprockets looks to the manifest to generate the source attribute of this script tag. A sample manifest is shown below that maps the logical path of the file to the filename including the digest:

```ruby
{ "application.js" => "application-ae0e5a78gfb231d11e07e00ec30g39f0a.js" }
```

In this example, the logical path of the asset – `application.js` – is mapped to the generated file name of the asset including the digest value. In the example below, which is a reverse mapping, further details of the asset are available including mtime, logical path, and so on.

```ruby
{
  "application-2e8e9a7888bdbd11e97effec30214a82.js" =>
  {
    "logical-path" => "application.js",
    "mtime" => "2016-06-16T23:09:08-06:00",
    "digest" => "2e8e9a7888bdbd11e97effec30214a82"
  }
}
```

Another hash is used to expire caches of Sprockets, so you can actually use the same directory and use the assets that you precompiled in the previous deploys. Later you can use this information to expire all the assets that you do not want to be in that folder anymore. There are more things about Sprockets that can be found in the Sprockets documentation and source code, including MIME types, dependency resolvers, transformer suffix, bundle metadata reducer.

## sprockets-rails

So a part of Sprockets, the asset pipeline is made by the `sprockets-rails` gem, and as you can guess, all this gem does is to integrate Sprockets to our Rails application so it defines helpers that we use in our application, like the examples below:

```ruby
javascript_include_tag
stylesheet_link_tag
```

The gem also configures the Sprockets environment without the configurations we have in the config initializer in `/assets`. It also checks the precompile list, which has been a feature since Sprockets version 3. The gem also makes it easier to know when we make mistakes in development, for example by not including an asset in the assets precompile list.

For example, if we were to write the following in our template:

```erb
<%= javascript_include_tag 'foo' %>
```

 This gem makes it possible to raise an exception that is telling you that we need to include that `foo.js` file in the manifest before using it in development. The exception in this example would be `Sprockets::Rails::Helper::AssetNotPrecompiled`.

## sass-rails

Another gem that we have is `sass-rails` gem, so like I said before, the `SassProcessor` is built-in into Sprockets itself, but there are some particularities of integrating Sass with Rails that needs to be done in this gem. The gem defines the generators that will be used by the Rails generator when we make a new scaffold that will also generate the corresponding Sass files. It also creates an importer that knows how to handle globs, paths, and ERB to support having something like this in your Sass files:

```scss
@import "foo/*"
// bar.scss.erb
@import "bar"
```

Here we are using glob imports and importing an ERB file, which would not work without the gem. It also configures the Sass processor with all the information we have in our Rails application.

## execjs

The third gem is the `execjs` gem. It allows you to run JavaScript code inside the Ruby environment and it uses the JavaScript environment that is available to you in the machine. We have some runtimes that work by default in the gem, like the Node.js environment and the V8 Google interpreter. The JavaScript code can be run directly within the Ruby VM. Using the gem is really simple as you can see from the examples below:

### Examples

```ruby
require 'execjs'
ExecJS.eval "'red yellow blue'.split(' ')"
# => ["red", "yellow", "blue"]
```

```ruby
require 'execjs'
require 'open-uri'
source = open('https://coffeescript.org/v1/browser-compiler/coffee-script.js').read

context = ExecJS.compile(source)
context.call('CoffeeScript.compile', 'square = (x) -> x * x', bare: true)
# => "var square;\nsquare = function(x) {\n  return x * x;\n};"
```

Here we are actually getting the CoffeeScript source code from the CoffeeScript website and compiling CoffeeScript code using Ruby. So as you can see, this gem is used by the coffee-script gem to compile CoffeeScript code to JavaScript. That brings us the the next gem, which is the coffee-rails gem.

## coffee-rails

All this gem does is configures generators, so if you don't use generators, you actually don't need the gem. It also defines a template handler so you can call handler CoffeeScript files from your controllers.

### Asset generation in development

In development, when you are using the `javascript_include_tag` as below:

```erb
<%= javascript_include_tag 'application'%>
```

The method generates the following HTML code that points to the digest version of that file:

```ruby
<script src="/assets/application.debug-ddbd4593b22ac054471df143715c8ce65ef84938965c7db19d8a322950ec65b6.js"></script>
             | path
                     | name
                                | suffix
                                      | SHA1 of file contents
                                                                                                       | extension
```

Note that the filename, is composed of the _path_ to the asset, the _name_ of the asset, the asset _suffix_, the SHA1 _digest_ of the file contents, and the _extension_ indicating file type. The `debug` suffix tells Sprockets that the debug pipeline is being used. When Sprockets generates the file in response to a request, it uses the debug pipeline which is defined like this:

```ruby
register_pipeline :debug do
  [SourceMapCommentProcessor]
end
```

The pipeline generates your asset, and puts a SourceMapComment in the end of the file. At the end of the JavaScript code, you are going to see a comment that looks something like this:

```js
//# sourceMappingURL=application.js-bf4cd805a31db054ae1dr1417f5c8ce72s13468ae23cbdb19d4a3bb010eh11f3.map
```

This is telling your browser how to get all the information about the source code via this source map file. To build the source code of this asset, Sprockets is going to use the default pipeline. The default pipeline is defined as shown below. It's just a small function call inside the Sprockets environment, and what this function call does is check if you have any kind of bundle processor for that MIME type that we are going to handle and use that bundle processor to build the asset.

```ruby
register_pipeline :default do |env, type, file_type|
  env.default_processors_for(type, file_type)
end

def default_processors_for(type, file_type)
  bundled_processors = config[:bundle_processors][type]
  if bundled_processors.any?
    bundled_processors
  else
     self_processors_for(type, file_type)
  end
end
```

For JavaScript, it uses the `bundled_processors` already configured inside Sprockets. In the bundle processor, all of the required files are compiled and merged to compose the final output file. To do this, Sprockets is going to use the _self pipeline_. The self pipeline is defined like this:

```ruby
register_pipeline :self do |env, type, file_type|
  env.self_processors_for(type, file_type)
end

def self_processors_for(type, file_type)
  processors = []

  processors.concat config[:postprocessors][type]
  if type != file_type && processor = config[:transformers][file_type][type]
    processors << processor
  end
  processors.concat config[:preprocessors][type]

  if processors.any? && mime_type_charset_deteceter(type)
    processors << FileReader
  end

  processors
end
```

First, it determines the `postprocessors`, `transformers`, and `preprocessors`, for that MIME type. To  read the file from the file system, it adds a new processor that is the `FileReader` that reads the file system to get the source code. You can see that it is a pipeline where each component provides output which is used as input for the next component. In the end, the bundler processor merges all of the output and the result is sent back to the browser. This how the asset compilation works in development. The key difference between development and production is that in production, all of this happens in the precompile task and only the resulting static asset is returned to the browser. We can now use this knowledge to extend Sprockets itself.

## Creating new directives

We can for instance, create new directives. For example the code below is from a real world use case:

```ruby
class NpmDirectiveProcessor < Sprockets::DirectiveProcessor
  def process_npm_directive(path)
    dirs = node_modules_paths(@filename)
    uri, deps = @environment.resolve!(
      path,
      accept: @content_type,
      pipeline: :self,
      load_paths: dirs
     )
    @dependecies.merge(deps)
    @required << uri
  end
end
```

We have an `NpmDirectiveProcessor` that goes to your `node_modules_path` and tries to get the dependencies from the Npm installation. We create a new directive processor that is inherited from `Sprockets::DirectiveProcessor`. Sprockets uses a convention that every method that starts with `process` and ends with `directive` is going to be used by directive processor. For example, if you have the `NpmDirectiveProcessor`, the method name will be `process_npm_directive`. After that, we just register that preprocessor for the appropriate MIME type with the appropriate processor.

```ruby
register_preprocessor 'application/javascript', 'NpmDirectiveProcessor'.new(comments: ['//', ['/*', '*/']])
```

Below is an example of loading the `lodash` library via Npm module:

```js
// app/assets/javascripts/my_component.js
//= npm lodash
```

Another real world example, is were we have a lot of images that are SVG but we also have to support browsers that do not support SVG. So, we have to convert the images from SVG to PNG. That happens automatically in the asset precompiling rake task. All we need to do is register a transformer from SVG to PNG.

```ruby
environment.register_transformer 'image/svg+xml', 'image/png', SVGTransformer.new
```

We can use something like the code below when we need to generate `foo.png` from `foo.svg`. If we only have the SVG version in our file system, we can dynamically generate the PNG file on-the-fly from our SVG files in the `../images` folder. An example of that is shown below using the `link` option:

```js
// app/assets/config/manifest.js
// Given you have foo.svg
//= link foo.png
// or
//= link_tree ../images .png
```

This is the real code. It's just a `call` method that gets the input that is the SVG source code and uses RMagick to generate the PNG file which is returned as a binary blob under the `data` Hash key.

```ruby
require 'rmagick'

class SvgTransformer
  def self.call(input)
    image_list = Magick::Image.from_blob(input[:data]) { self.format = 'SVG' }
    image = image_list.first
    image.format = 'PNG'

    { data: image.to_blob }
  end
end
```
