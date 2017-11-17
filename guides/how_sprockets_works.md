> This document is based off of a transcript from [Rafael’s 2016 RailsConf talk “How Sprockets” works](https://www.youtube.com/watch?v=CzFFYelG7WY). It’s been edited to make sense outside of a talk context. Rafael is amazing and does great work with Sprockets and Rails.

Rails is presented in a lot of different ways, it's not just the Rails gem but there are a lot of different components, for example: Action View, Spring, jquery-ujs, Turbolinks, Sprockets.

You can see that the Rails project is present in almost all the layers of your computer. You have things on the process level, like Springs and also things running in the browser, like jquery-ujs and Turbolinks.

This doc is to present something that is not well-known, that is how the assets pipeline of Rails works right now. We will talk about why you need the assets pipeline, which are the gems responsible for it, and how it works in a Rails application and we will show you how to extend the assets pipeline.

First, why do we need an assets pipeline? Before we had assets pipeline in Rails, introduced in Rails 3.1, we had a question: “Where should I put my assets?”. We did not have any kind of convention how to handle client-side coding in the Rails applications, so we had to put our assets in the public folder. Usually we ended up with a lot of files that we don't even know if they are being used or not.

Rails is about convention and configuration, so that was not something that we should have done with our client-side code. We also have another problem: we had to make some trade-offs between code organization and performance. Browsers had limitations, the Internet was too slow. There are tradeoffs to make, for example should we create many small self-contained files or do fewer assets request in our applications? Initializing an HTTP connection to download an asset is expensive, yet working inside of 1 really large file is difficult.

Should we write legible code? Or should we transmit fewer bytes to the clients? There were some technologies that were being used in that time, but could not be used easily in Rails applications. Technologies like CoffeeScript, Sass, and ECMAScript 6. To solve these problems, the asset pipeline was created.

But how does this assets pipelines work in Rails? Right now, we have some conventions for our client-side code, so our assets live in the `app/assets` folder and they are also `lib/assets` and `vendor/assets` folders. Assets are compiled on-the-fly in development and need to be precompiled in production and we also have asset name fingerprinting so the digest of the asset can do cache busting.


The assets pipeline is made by a bunch of gems:

- sprockets
- sprockets-rails
- sass-rails
- execjs
- coffee-rails

We will go through each and talk about how they work. The first gem that I'm going to talk about is Sprockets. It's the gem that makes it possible to compile and serve all assets. Sprockets defines a processors pipeline so you can extend the way your assets are processed.

Sprockets has some key components that are:
- processors
- transformers
- compressors
- directives
- environments
- manifest
- pipelines

The processors are the most important components in Sprockets. All the functionality inside of Sprockets is implemented by a processor. This is similar to how Railties is also a rails engine. The interface for a processor is any `call`-able object that accepts an input hash and returns a hash as metadata.

```ruby
-> (input) {
  data = input[:data].gsub(";", "")
  { data: data }
}
```

Example of valid sprockets processor

So this will be called, it's actually a valid Sprockets processor. It's doing something that is easy to understand. Just remove semicolons from the end of your JavaScript files, because we don't need semicolons in JavaScript code. So, it's taken an input that has some special keys that I'm going to talk about later and it has to return another hash that has data as a result of the processor running.

The input hash has these keys by default:
`:data` - String assets contents
`:environment` - Current `Sprockets::Environment` instance
`:cache` - A `Sprockets::Cache` instance
`:uri` - asset URI
`:source_path` - full path to orginal file
`:load_path` - current load path for filename
`:name` - logical path for filename
`:conten_type` - content type of the output asset
`:metadata` - Hash of processor metadata

The return hash has these keys:
`:data` - Replaces the assets `input[:data]` to the next processor in the chain
`:required` - A Set of String asset URIs that `Bundle` processor should concatenate  together
`:stubbed` - A Set of String asset URIs that will be omitted from the `:required` set
`:links` - A Set of String asset URIs that should be compiled along with the assets
`:dependencies` - A Set of String cache URIs that should be monitored for caching
`:map` - An Array of source maps for the assets
`:charset` - The mime charset for an asset

The required is really interesting(as we will see later), each dependency from your asset files will be stored in this field.

There are a lot of interesting built-in processors as:

- BabelProcessor
- CoffeScriptProcessor
- SassProcessor
- BundlerProcessor
- etc...

BundlerProcessor is used to run concatenated assets rather than individual files.

To register a processor in Sprockets, we use this syntax.

register_bundle_processor 'application/javascript', Bundle
register_bundle_processor 'text/css', Bundle

 We are telling that for any `application/javascript` mime types file, we are using the `Bundle` processor to take care of these files and concatenating them in the same file. So the `Bundle` processor takes a single file asset and prepends all the `required` URIs in the contents.
Transformer

A transformer is a processor that converts a file from one format to another format.
So, one of the examples is the CoffeeScript transformer that gets CoffeeScript file and returns a JavaScript file.

```ruby
register_transformer 'text/coffescript',
                     'application/javascript',
                     CoffeScriptProcessor
```

The permutation of these processors are really simple.

```ruby
module CoffeScriptProcessor
  #......

  def self.call(input)
    data = input[:data]

     js, map = input[:cache].fetch([self.cache_key, data]) do
       result = CoffeScript.compile(data, sourceMap: true, sourceFiles: [input[:source_path]])
       [result[‘js’], decode_source_maps(result[‘v3SourceMap’])]
     end

     map = SourceMapUtils.combine_source_maps(input[:metadata][:map]), map)
     { data: js, map: map }
  end
end
```

So, it's a callable object that takes an input and it actually goes through the CoffeeScript compiler and returns the result of this operation as the data of the returning hash.

Compressor

Compressors are a special kind of bundle processors because it runs on the concatenated file. You register compressor using following syntax:

```ruby
  register_compresor ‘application/javascript’, :uglify, UglifierCompressor
```

The main difference between the compressor and the bundle processor is compressors are used differently and you can have only compressor by mime types. So this Sprockets has a special syntax to enable compressors. You can, for instance, compress any JavaScript file using this syntax.

```ruby
  env.js_compressor = :uglify
```
Directives

I'm sure you all have seen directives before because they are just special comments that declares your bundlers and their dependencies. This, for instance, is important for the application js that is right now generated by new Rails applications.

```js
  // app/assets/javascripts/application.js
  //= require jquery
  //= require jquery-ui
  //= require users
  //= require_tree .
```

So it's telling us that to generate these application js file, we have to require these three files, and also all the files inside the same directory of the application js. So, another special kind of directive that we have in Sprockets three were the precompile lists that you are telling Sprockets to actually precompile these two files in production.
```ruby
Rails.application.config.assets.precompile << %w(application.js application.css)
```

Sprockets has special support to `Procs` on the precompilation, so before, in Sprockets three, we had this code that is telling us to precompile all the known JavaScript and style sheet files in the app directory.
```ruby
LOOSE_APP_ASSETS = lambda do |logical_path, filename|
  filename.start_with?(::Rails.root.join(“app/assets”).to_s) &&
    ![‘.js’, ‘.css’, ‘’].include?(File.extname(logical_path))
End

config.assets.precompile = [LOOSE_APP_ASSETS, /(?:\/|\\|\A)application\.(.css|js)$/]
```

 As you can see, this code is not easy to understand, so in Sprockets four, we have a new syntax for that.

```js
// app/assets/config/manifest.js
//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css
//= link my_engine

// my_engine/app/assets/config/my_engine.js
//= link_tree ../images/bootstrap
```

It's called the link_directive, so it's easy to understand what's going on there, so you can actually see that all the images in the image directory is going to be precompiled as the JavaScript and the style sheets show. And I can actually use this directive to compose new libraries, so I have that link to my engine, that's also defining its own manifest file. So, it's now easy to understand and to compose to. Not that we are going to remove the precompile list, but these new directives are there to help to exchange the precompile list. So we have all these directives by default in Sprockets. And I will show later how you can extend the directives to create your own directives.

Environment

Another component of Sprockets is the environment, and that is actually where your code actually runs. The environment has methods to retrieve and serve assets, change the load path, and registering processors. So, when you're doing web requests to your assets file, what is going on is that the Sprockets' environment is running and it is trying to find that specific file and send it back to you.

```ruby
environment = Sprockets::Environment.new
environment.find_assets(‘application.js’)
```

So the environment is also where you call all those methods that I showed before, that you can register processors, compressors, things like that. And a part of environment, we have the manifest that is just a log of the contents of all all your precompiled assets in a directory and it is used to do fast lookups without having to actually compile your assets code.
```ruby
environment = Sprockets::Environment.new
Environment.register_transformer ‘image/svg+xml’,
                                                       ‘image/svg’,
                                                        SVGTransformer.new
```

This object is really simple, it actually only points the assets path the the fingerprinted version that's generated by Sprockets.

```ruby
javascript_include_tag ‘application’
#<script
#src=”/assets/application.debug-
ddbd4593b22ac054471df143715c8ce65ef84938965c7db19d8a322950ec65b6.js”
#></script>
```

So, when you're having your code something like JavaScript_include_tag 'application', what's going on is that to generate that source attribute of this script tag, Sprockets is going to manifest the object that has a hash like this

```ruby
{ “application.js” => “application-2e8e9a7888bdbd11e97effec30214a82.js”,
“application.js” => “application-ae0e5a78gfb231d11e07e00ec30g39f0a.js” }
```


Inside that only maps the name without the dashes to the name with the dashes and it also contains the opposite way, where you have the daughter's name and you can find either the mtime and the logical path of that file.

```ruby
{ “application-2e8e9a7888bdbd11e97effec30214a82.js” =>
     {‘logical-path’ => “application.js”,
       ‘mtime’ => “2016-06-16T23:09:08-06:00”,
       ‘Digest’ => “2e8e9a7888bdbd11e97effec30214a82”} }
```

 Another hash is used to expire caches of Sprockets, so you can actually use the same directory and use the assets that you precompiled in the previous deploys. And you can later use this information to expire all the assets that you do not want to be in that folder anymore. There are more things about Sprockets that I'm not going to talk about here, but you can find information, there is Sprockets documentation and also source code. There are mime types, dependency resolvers, transformer suffix, bundle metadata reducer.


sprockets-rails

 So a part of Sprockets, the assets pipeline is made by the Sprockets-rails gem, and as you can guess, all this gem does is to integrate its Sprockets to our Rails application so it defines helpers that we use in our application, like
`javascript_include_tag`
`stylesheet_link_tag`

It configures the Sprockets environment without the configurations we have in the configure neutralized assets. It also checks the precompile list. This is a thing not new but since Sprockets three. We can actually know when we do mistakes in development, not including the assets precompile list. This gem is impossible to make this exception, that is telling you that we need to include that foo.js file in the manifest before actually using that in development.


saas-rails

Another gem that we have is sass-rails gem, so like I said before, the Sass processor is built-in into Sprockets itself, but there are some particularities of integrating Sass with Rails that needs to be done in this gem. And we have four instances. Each gem defines the generators that we have when we are running, when we discovered something, it generates new size files. It also creates an importer that knows about how to handle globs, paths, and ERB and that means that if you have something like this in you Sass files,

```scss
@import “foo/*”
// bar.scss.erb
@import “bar”
```

like using glob imports or trying to import some kind of ERB file, you will need the gems. Without the gem, you cannot actually make this work. And it also configures the Sass processor with all the information we have in our Rails application.

Execjs

The third gem is the execjs gems. It allows you to run JavaScript code inside the Ruby environment and it uses the JavaScript environment that is available to you in the machine. We have some options that is working by default in the gem, like the Node.js environment and the V8 Google interpreter. And to use the gems is really simple. You actually run a JavaScript code inside the Ruby one.

```ruby
require “execjs”
require “open-uri”
source = open(“http://coffeescript.org/extras/coffee-script.js”).read

context = ExecJS.compile(source)
context.call(“CoffeeScript.compiler”, “square = (x) -> x * x”, bare: true)
# => “var square;\nsquare = function(x) {\n   return x * x;\n};”
```

Here we are actually getting the CoffeeScript source code from the CoffeeScript website and compiling CoffeeScript code using Ruby. So as you can see, this gem is used by the coffee-script gem to compile CoffeeScript code to JavaScript. That brings us the the next gem, which is the coffee-rails gem.

coffee-rails

All the gem does is configures generators, so if you don't use generators, you actually don't need the gem. And it also defines a template handler so you can call handler CoffeeScript files from your controllers.


Assets generation in development

In development, when you have this code, the javascript_include_tag,

```erb
<%= javascript_include_tag ‘application’%>
```
it's going to generate this HTML code that points to the digestive vessel of that file.

```ruby
javascript_include_tag ‘application’
#<script
#src=”/assets/application.debug-
ddbd4593b22ac054471df143715c8ce65ef84938965c7db19d8a322950ec65b6.js”
#></script>
```

 Note that after the application name, there is a .debug, that is telling Sprockets that debug pipeline is going to be used. So, when the browser does the request to that file, sprockets-rails understands that that file is going to use debug pipeline of Sprockets and the debug pipeline of Sprockets is defined like this.

```ruby
register_pipeline :debug do
  [SourceMapCommentProcessor]
end
```

It's actually a pipeline that is going to generate your asset, but put a SourceMapComment in the end of the file. So, after the entire JavaScript code, you are going to see something like this,

```js
//# sourceMappingURL=application.js-
bf4cd805a31db054ae1dr1417f5c8ce72s13468ae23cbdb19d4a3bb010eh11f3.map”
```

 and this is telling your browser to actually get all the information about the source code in this source map file. So, to build the source code of this file assets, Sprockets is going to use the default pipeline. This is inside the source map homemade code, so I'm not going to show here. But the default pipeline is defined like this, it's just a small function call inside the Sprockets environment, and what this function call does is check if you have any kind of bundle processor for that mime type that we are going to handle and use that bundle processor to build the asset.

``ruby
register_pipeline :default do |env, type, file_type|
  env.default_processors_for(type, file_type)
end
``


```ruby
def default_processors_for(type, file_type)
  Bundle_processors = config[:bundle_processors][type]
  if bundled_processors.any?
    bundled_processors
  else
     self_processors_for(type, file_type)
  end
end
```

For JavaScript, it used the file bundled_processors inside the Sprockets. In the bundle processor, you compile all the required files and merge them and to compile each individual required file, Sprockets is going to use the self pipeline and the self pipeline is defined like this:

``ruby
register_pipeline :self do |env, type, file_type|
  env.self_processors_for(type, file_type)
end
``

The same thing of the default pipeline but calling it a different function.

```ruby
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

What that function does is build a stack of processors.
First, it gets out the postprocessors of that mime type. Later, the transformers of that mime type and then it gets out the preprocessors of that mime type. And to actually read the file, from the file section it adds a new processor that is the file reader that actually goes to the file section and gets this source code, so it's built stacked like this, where each component uses the input of the previous component. So, first it reads from the file section and the CoffeeScriptProcessor and actually compiles the CoffeeScriptCode and returns the JavaScript code and later the DirectiveProcessor gets all the requirements and all the directives. So, in the end, the bundler processor merge all of them and the result is sent back to the browser. So this how the assets compilation works in development and the key difference between development and production is that in production, all of this happens in the precompile task and only a static asset is returned to the browser, so nothing of that is going to happen in your run time. So, how can we use all this knowledge to the extend the Sprockets?

Creating new directives

We can, for instance, create new directives, so this code is actually real, it's from the shop file application.

```ruby
class NpmDirectiveProcessor < Sprockets::DirectiveProcessor
  def process_npm_directive(path)
    dirs = node_modules_paths(@filename)
    uri, deps = @environment.reslove!(
      path,
      accept: @content_type,
      pipeline: :self,
      load_paths: dirs
     )
    @dependecies.merge(deps)
    @required << uri
  end

  # ...
end
```

We have an NpmDirective that goes to your node_modules_path and trys to get the dependencies from the Nmp installation. So, we create a new directive processor that's inherited from this directive processor and Sprockets uses a convention that everything single method that starts with process and ends with directive is going to be used to the directive processor, so, if you have the NpmDirective, the method is processing NpmDirective. And after that, we just register that preprocessor for all the JavaScript files and we associate the right processor and we can use this kind of thing in our JavaScript components now.
```ruby
Register_preprocessot ‘application/javascript’,
  NpmDirectiveProcessor.new(comments: [“//”, [“/*”, “*/”]])
```
We can actually load the lodash library from the Npm module installation.

```js
// app/assets/javascripts/my_component.js
//= npm lodash
```

Another example that we have in the shop file application is we actually have a lot of images that are SVG but we have to actually support EA8, I think. So, we have to convert them from SVG to PNG. So, that happens automatically in the precompiling. All we need to do is register a transformer from SVG to PNG.
```ruby
environment.register_transformer ‘image/svg+xml’,
  ‘image/png’,
  SVGTransformer.new
```
 So we can use a thing like this we can actually ask to generate the foo.png file from the foo.sj that we only have the SVG version in our file system or we can also ask to generate the other PNG file from our SVG files that are inside the images folder and the call to do that is really simple.

```js
// app/assets/config/manifest.js
// Given you have foo.svg
//= link foo.png
// or
//= link_tree ../images .png
```

This is the real code. It's just a call method that actually gets the input that is the SVG source code and ask the image to change to generate a PNG file and we return that PNG file in the data.





```ruby
require ‘rmagick’

class SvgTransformer
  def self.call(input)
    image_list = Magick::Image.from_blob(input[:data]) { self.format = ‘SVG’ }
    image = image_list.first
    image.format = ‘PNG’

    { data: image.to_blob }
  end
end
```

So, my effort in this talk is that I know that Sprockets is used in many Rails applications right now, but many users don't even know how it exists. Many users don't know how it works. Even I didn't know how it works two years ago, so it's important for you to try to understand your tools. Documenting your understandings, doing talks or writing documentation for these tools, and share with the community. So, we are right now in the effort to save Sprockets so you can see more about that tomorrow in Richard's talk that's called Saving Sprockets, of course. And that's it. So, we are hiring in Shopify, so if you want to work with me, we have a lot of different open positions right now for all the different offices. You can talk with our team in the show room, there is a Shopify booth there. And also, we had two talks before mine, four Shopify people and we are going to have a module, so we have today, how we test your Rails at scale at Shopify, I think after this talk, and we are going out to see the Rails 5 Features that you haven't heard about. We share everything. So that's it, thank you.


