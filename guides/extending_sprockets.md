# Extending Sprockets

Sprockets can use custom processors, compressors, and directives. This document is intended for library authors who want to extend Sprockets functionality.

## Contents

- [Types of Extensions](#types-of-extensions)
  - [Processors](#processors)
  - [Transformers](#transformers)
  - [Compressors](#compressors)
  - [Exporters](#exporters)
- [Extension Interface](#extension-interface)
  - [Extension Keys](#extension-keys)
  - [Extension Metadata Keys](#extension-metadata-keys)
  - [Register Mime Type](#register-mime-types)
- [Adding Directives to your Extension](#adding-directives-to-your-extension)
- [Adding ERB Support to your Extension](#adding-erb-support-to-your-extension)
- [Supporting All Versions of Sprockets in Processors](#supporting-all-versions-of-sprockets-in-processors)
  - [Registering All Versions of Sprockets in Processors](#registering-all-versions-of-sprockets-in-processors)

## Types of Extensions

Sprockets supports a few different ways to extend functionality.

- processors
- transformers
- compressors
- exporters

For a detailed explanation of each see the respective sections below.

Sprockets ships with a number of built in processors, transformers and compressors. You can see all the defaults registered in `lib/sprockets.rb`.

### Processors

There are two types of processors: preprocessors and postprocessors.

A preprocessor is called as an asset is loaded. Generally preprocessors take in a raw file and convert its contents. For example the `DirectiveProcessor` is the processor that is responsible for reading in the Sprockets directives such as:

```js
//= require "foo"
```

It will then load in the `foo` file and add its contents to the original file.

A postprocessor is called after all of the transformers run. Generally postprocessors do a final transformation to an asset before it is ready for bundling in the asset pipeline.

For example, imagine that you like to write JavaScript without semicolons. However, your project uses a CoffeeScript library. Since CoffeeScript adds semicolons during compilation, you might make a processor that removes all `;` from JavaScript files since CoffeeScript compiles to JavaScript. A simple implementation of this could be a proc:

```ruby
remove_semicolons_processor = -> (input) {
  data = input[:data].gsub(";", "")
  { data: data }
}
```

When you register this processor as a postprocessor your CoffeeScript library will first be compiled to JavaScript, then post-processed by this processor, thus removing all semicolons from the output.

Without postprocessors, you would have to ensure that the CoffeeScript transformer is run _before_ your processor so you would have to insert it after the CoffeeScript transformer much like two Rack middlewares that have an order-dependence on one another. With postprocessors, you can register your processor as a postprocessor and not need to worry about ordering it after the CoffeeScript transformer.

## Transformers

A transformer takes one asset and converts it into another asset. For example the `CoffeeScriptProcessor` is what takes a file with a `.coffee` file extension and returns a `.js` file.

### Transformers

Like a preprocessor, a transformer will return the contents of the file in a `:data` key, and any other metadata.

You can register a transformer like this:

```ruby
Sprockets.register_transformer 'text/coffeescript', 'application/javascript', CoffeeScriptProcessor
```

The first argument is the mime type of the file that the processor accepts. The second argument is the mime type that it generates, and the last argument is the object that responds to `call`.

For example, say you wanted to have Sprockets process a `.html` file, and output the mime type as application/javascript. To accomplish this, you would do the following:

```ruby
Sprockets.register_transformer 'text/html', 'application/javascript', MyTemplateProcessor
```

### Compressors

A compressor takes in an asset, and returns a smaller version of that asset. For example the uglifier compressor takes in a JavaScript file, it then removes the whitespace and applies other space saving techniques and returns a smaller JavaScript source.

Compressors must respond to `call` and return a `:data` key in a hash similar to a processor.

You can register a compressor like this:

```ruby
Sprockets.register_compressor 'application/javascript', :uglify, UglifierCompressor
```

Registering a compressor allows it to be used later. After registering a compressor you can activate it using the `js_compressor=` or `css_compressor=` method on the environment or Sprockets global.

```ruby
Sprockets.register_compressor 'text/css', :my_css, MyCssCompressor
Sprockets.css_compressor = :my_css
```

Compressors only operate on JavaScript and CSS. If you want to compress a different type of asset, use a processor (see "Processors" above) to process the asset.

## Exporters

An exporter takes a compiled asset and writes it to disk. The default exporters are `FileExporter` which writes an asset's compiled source to disk and `ZlibExporter` that will produce a `.gz` file extension.

You can write your own exporter:

```
register_exporter '*/*', Sprockets::Exporters::ZlibExporter
```

First argument is the mime type of files that the exporter will operate on. For your convenience, a `Sprockets::Exporters::Base` class is provided for you to inherit from. Details about the required interface for an exporter are in that class.

Your exporter gets initialized once for each asset to be exported by sprockets with the following keyword arguments

 - asset (Instance of Sprockets::Asset)
 - environment (Instance of Sprockets::Environment)
 - directory (Instance of String)

A `setup` method is called right after the exporter is initalized. Your exporter is expected implement a `skip?` method. If this method returns true then sprockets will skip your exporter and move to the next one. An instance of `Sprockets::Logger` is passed into this method that can be used to indicate to the user what is happening. This method is called synchronously.

The work of writing the new asset to disk is performed in the `call` method. This method is potentially called in a new thread and should not mutate any global state. A `write` method is provided that takes a `filename` to be written to (full path) and yields an IO object.

## Extension Interface

A processor is expected to respond to `call()` and it accepts a hash of file contents. It is expected to return a hash that includes a `:data` key. The value returned in the `:data` key will be used as the contents for the file. Any other keys returned will be stored in the `:metadata` hash of an asset. For example, this result:

```ruby
class HelloWorldProcessor
  def call(input)
    return { data: input[:data] + "\n'hello world'" }
  end
end
```

Would append the string `'hello world'` on a new line to any asset.

For Sprockets to call the processor it must be registered. If we wanted this processor to be called with any JavaScript files we would use the JavaScript mime type `application/javascript` and pass in the object that responds to call, in this case an instance of the `HelloWorldProcessor` class:

```ruby
Sprockets.register_preprocessor('application/javascript', HelloWorldProcessor.new)
```

To register a processor as a postprocessor instead of a preprocessor, invoke the `register_postprocessor` command instead:

```ruby
Sprockets.register_postprocessor('application/javascript', HelloWorldProcessor.new)
```

### Extension Keys

The `call` interface returns a hash. In different versions of Sprockets there may be different keys. This doc is for Sprockets 4 (master). You can see these values being passed into processors [in the Sprockets loader](https://github.com/rails/sprockets/blob/a9b53daaa5404443c0684103b7f83cd5be208575/lib/sprockets/loader.rb#L148-L161).

- `:data` - [String] Contains the contents of the file being passed to the your processor.

Example:

```
'var foo = "bar"'
```

- `:uri` - [String] A full URI to the asset, may include custom Sprockets params.

Example:

```
"file:///Users/richardschneeman/Documents/projects/sprockets/test/fixtures/default/application.coffee?type=application/javascript",
```

- `:filename` - [String] Full path to asset on disk.

Example:

```
"/Users/richardschneeman/Documents/projects/sprockets/test/fixtures/default/gallery.js\"
```

- `:load_path` - [String] The load path that was used to find the asset.

Example:

```
"/Users/richardschneeman/Documents/projects/sprockets/test/fixtures/default"
```

- `:name` - [String] The name of the file being loaded without extension.

Example

```
"gallery"
```

- `:content_type` - [String] The coresponding mime content type of the asset.

Example:

```
"application/javascript"
```

- `:metadata` - [Hash] Extra data, see the "metadata" section.

Example:

```
# See metadata section for more info
{
  dependencies: [].to_set
  map: {
    # ...
  }
}
```

- `:cache` - [Sprockets::Cache] A cache object you can use to store and retrieve intermediate objects. You can use `Cache#get`, `Cache#set` and `Cache#fetch` api. Refer to method docs for more info. If using paths for the key or contents, use `Sprockets::Environment#compress_from_root` and `Sprockets::Environment#expand_from_root` as the location of of your files absolute path will change.


- `:environment`  [Sprockets::Environment] Now you have direct access to all 105 methods that Sprockets uses! Use carefully, we may consider limiting this in the future. If you have feedback on what methods you need or use please say hi, Open an issue and let the Sprockets team know.

### Extension Metadata Keys

While you can store arbitrary keys in the metadata returned by your extension, there are some with special meaning and
uses inside of Sprockets. More may be added in the future.

Anything you add to the metadata will be stored in the Sprockets cache for the asset.

- map: This key contains a source map for the asset.

A source map is a way to tell a browser how to map a generated file to an original for example if you write a
CoffeeScript file, Sprockets will generate a JavaScript file which is what the browser will see. If you need to debug
this javascript file it helps if you know where the in your original CoffeeScript file the generated JavaScript code
came from. The source map tells the browser how to map from a generated file to an original.

Sprockets expects this map to follow the [source map spec](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k).

- charset: This key contains the mime charset for an asset.

A charset is the encoding for text based assets. If you do not specify a charset then one will be automatically assigned
by sprockets based on the encoding type of the contents returned in the `:data` key. Normally you want that, the only
time you don't want that is if you're working with binary data, or data you don't want to be compressed. If Sprockets
sees a `charset` then it will think that the contents of the file are text and can be compressed via GZIP. You can avoid
this by setting the field manually.

```ruby
return { data: data, charset: nil }
```

WIP the format of the source map may be subject to change before 4.0 is released. Currently it takes a `:original`
and `:generated` key which each hold an array of line and column numbers. Line numbers are 1 indexed column numbers
are 0 indexed. The first character of a file will always be `[1,0]`.

- required: A `Set` of String Asset URIs that the Bundle processor should concatenate together.

- stubbed: A `Set` of String Asset URIs that will be omitted from the `:required` set.

- links: A `Set` of String Asset URIs that should be compiled along with this asset.

- dependencies: A `Set` of String Cache URIs that should be monitored for caching.

### Register Mime Types

You can add new mime-types to Sprockets by using the `register_mime_type` method. For example:

```ruby
Sprockets.register_mime_type 'application/json', extensions: ['.json'], charset: :unicode
Sprockets.register_mime_type 'application/ruby', extensions: ['.rb']
```

The first method is the mime-type of the object. The `:extensions` key passed to the second argument contains an array of all the extensions for the given mime type. An optional charset can be registered. This should only be used for text based mimetypes.

Your extension may have multiple parts for example some people use `.js.coffee` when this file type is used, we do not wish it to process as javascript first and then as coffee script so we register this entire extension:


```ruby
Sprockets.register_mime_type 'text/coffeescript', extensions: ['.coffee', '.js.coffee']
```

## Adding Directives to your Extension

If you are writing a transformer you likely also want it to understand Sprockets directives (such as the ability to `require` other files). You don't have to add this functionality in manually, instead you can register a custom instance of `DirectiveProcessor` to run with your asset.

The `DirectiveProcessor` can be initialized with a `:comments` key that holds an array of characters that denote a comment. For example the coffeescript language uses `#` as a comment. We could apply directive support to coffeescript files by registering:

```ruby
Sprockets.register_preprocessor 'text/coffeescript', DirectiveProcessor.new(comments: ["#", ["###", "###"]])
```

## Adding ERB Support to your Extension

In Sprockets 4 file types are no longer "chainable" this means that if you wanted to use a `.coffee.erb` that it must be registered to sprockets explicitly. This is different from previous versions of sprockets where you would have to register only a `.erb` processor and then a `.coffee` processor and sprockets would chain them (first running erb then coffee).

The reason for the change is to have more explicit behavior. It helps sprockets know to do the right thing, decreases magic, and increases speed. It also means that as a library maintainer you must tell sprockets all the extensions you want your project to work with. Going with the coffee script example. You would need to register a mime type

<!---
Right now sprockets uses an "internal interface" to register erb files. I'm not actually sure how to register support for an ERB file correctly without using that interface, need to do more research

```
env.register_mime_type 'text/coffeescript+ruby', extensions: ['.coffee.erb', '.js.coffee.erb']

env.register_mime_type 'text/coffeescript', extensions: ['.coffee', '.js.coffee']
env.register_transformer 'text/coffeescript', 'application/javascript', CoffeeScriptProcessor
env.register_preprocessor 'text/coffeescript', DirectiveProcessor.new(comments: ["#", ["###", "###"]])
```

-->

## Supporting All Versions of Sprockets in Processors

If you are extending sprockets you may want to support all current major versions of sprockets (2, 3, and 4). The processor interface was deprecated from Sprockets 2 and a legacy shim was put into Sprockets 3. Now that Sprockets 4 is out that shim no longer is active, so you'll need to update your gem to either only use the new interface or use both interfaces. For example:

```ruby
# Sprockets 2, 3 & 4 interface

class MySprocketsExtension
  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(context, empty_hash_wtf)
    self.class.run(@filename, @source, context)
  end

  def self.run(filename, source, context)
    source + "/* Hello From my sprockets extension */"
  end

  def self.call(input)
    filename = input[:filename]
    source   = input[:data]
    context  = input[:environment].context_class.new(input)

    result = run(filename, source, context)
    context.metadata.merge(data: result)
  end
end

require 'sprockets/processing'
extend Sprockets::Processing

register_preprocessor 'text/css', MySprocketsExtension
```

This extension is registered to add a comment `/* Hello From my sprockets extension */` to the end of a `text/css` (.css) file.

To understand why all of this is needed, we need to look at the different interfaces for Sprockets 2, 3, and 4.

Sprockets 2 let you register a processor with a class that would be instantiated and the method `render` called on it you can [view the calling code in Sprockets 2.x](https://github.com/rails/sprockets/blob/2199a6012cc2b9cdbcbc0049361e5ee02770dff0/lib/sprockets/context.rb#L194-L202). It may have looked like this:


```ruby
# Sprockets 2.x interface

class MySprocketsExtension
  def initialize(filename, &block)
    # code
  end

  def render(variable, empty_hash_wtf)
    # code
  end
end

require 'sprockets/processing'
extend Sprockets::Processing

register_preprocessor 'text/css', MySprocketsExtension
```

You can also pass a block to both 2.x and 3.x+ processor interfaces, however the number of args the method takes has changed so it's very hard to do that method and support multiple processor interfaces.

This Sprockets 2.x `render` interface is deprecated, instead you should use the `call` interface which was introduced in Sprockets 3.x. Whatever you pass to the processor can have a `call` method, it does not need to be a class.


```ruby
# Sprockets 3.x+ interface

module MySprocketsExtension
  def self.call(input)
    # code
    result = input[:data] # :data key holds source
    { data: result }
  end
end

require 'sprockets/processing'
extend Sprockets::Processing

register_preprocessor 'text/css', MySprocketsExtension
```

So if you want 2, 3, and 4 to work you can pass in a class that also has a `call` method on it as well as a `render` instance method. To see how this can be done you can reference this [autoprefixer-rails pull request](https://github.com/ai/autoprefixer-rails/pull/85).

This way you're passing in an object that responds to 3.x's `call` interface and 2.x's `new.render` interface. In generally we're recommending people not use Sprockets 2.x and that they upgrade to Sprockets 3+. If it's easier on you, you can rev a major version and only support the new interface.


There are new hash keys introduced in Sprockets 4. The `:source_path` key contains the file that will hold the sourcemap of the current asset.

```ruby
# Sprockets 3.x+ interface

module MySprocketsExtension
  def self.call(input)
    file_where_source_map_will_end_up = input[:source_path]
    # code
    { data: result }
  end
end
```

If your application is making serious modifications to the source file (an example could be a coffee script file generating JS will be signifigantly different) then you'll want to calculate and return an appropriate `map` key in the `metadata` hash. See the "metadata" section for more info on doing this.

Once you've written your processor to run on all 3 versions of Sprockets you will need to register it. This is covered next.

### Registering All Versions of Sprockets in Processors

In Sprockets 2 and 3 the way you registered a processor was via `register_engine`. Unfortunately they have different method signatures. In Sprockets 4 you must first explicitly register a mime type and use the appropriate processor directive i.e. `register_transformer`, `register_preprocessor`, etc. To register a processor for all 3 versions of sprockets you could do it like this:

```ruby
# Sprockets 2, 3, and 4

if env.respond_to?(:register_transformer)
  env.register_mime_type 'text/css', extensions: ['.css'], charset: :css
  env.register_preprocessor 'text/css', MySprocketsExtension
elsif env.respond_to?(:register_engine)
  args = ['.css', MySprocketsExtension]
  args << { mime_type: 'text/css', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
  env.register_engine(*args)
end
```

To understand why this is all needed, we can break down the parts. First is how you register an "engine" with Sprockets 3:


```ruby
# Sprockets 3
env.register_engine '.css', MySprocketsExtension, mime_type: 'text/css', silence_deprecation: true
```

The use of `register_engine` is deprecated in Sprockets 3 and you will get a deprecation warning about it's use. We can pass in `silence_deprecation: true` to let Sprockets know that the inteface is going away, only do this on code you know works with Sprockets 4.

To get the `register_engine` code working with Sprockets 2 we have to do some version detection since Sprockets 2 will error if you try to pass a hash into it:

```
# Sprockets 2 & 3
args = ['.css', MySprocketsExtension]
args << { mime_type: 'text/css', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
env.register_engine(*args)
```

Next we see how to do it with Sprockets 4 when `register_engine` is removed:

```ruby
# Sprockets 4
env.register_mime_type 'text/css', extensions: ['.css'], charset: :css
env.register_preprocessor 'text/css', MySprocketsExtension
```

In reality you wouldn't need to add a mime type for JS and CSS assets since they're already there by default but you will for other filetypes for example `.coffee` or `.scss`. The above `register_mime_type` example is used for example purposes and wouldn't be required.

Sprockets 4 will not chain asset extensions so `.coffee.erb` is explicitly registered in addition to `.coffee`. If your application introduces a new mime/extension combo it will be responsible for registering all combinations.


## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).

