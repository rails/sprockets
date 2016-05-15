# Extending Sprockets

Sprockets can use custom processors, compressors, and directives. This document is intended for library authors who want to extend Sprockets functionality.

## Types of Extensions

Sprockets supports a few different ways to extend functionality.

- processors
- transformers
- compressors

For a detailed explanation of each see the respective sections below.

Sprockets ships with a number of built in processors, transformers and compressors. You can see all the defaults registered in `lib/sprockets.rb`.

## Processors

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

### Processor Interface

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

## Transformers

A transformer takes one asset and converts it into another asset. For example the `CoffeeScriptProcessor` is what takes a file with a `.coffee` file extension and returns a `.js` file.

### Transformer Interface

Like a preprocessor, a transformer will return the contents of the file in a `:data` key, and any other metadata.

You can register a transformer like this:

```ruby
Sprockets.register_transformer 'text/coffeescript', 'application/javascript', CoffeeScriptProcessor
```

The first argument is the mime type of the file that the processor accepts. The second argument is the mime type that it generates, and the last argument is the object that responds to `call`.

For example, say you wanted to have Sprockets process a `.html` file, and output the mime type as application/javascript. To accomplish this, you would do the following:

```ruby
  register_transformer 'text/html', 'application/javascript', MyTemplateProcessor
```

## Compressors

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

## Adding directives to your extension

If you are writing a transformer you likely also want it to understand Sprockets directives (such as the ability to `require` other files). You don't have to add this functionality in manually, instead you can register a custom instance of `DirectiveProcessor` to run with your asset.

The `DirectiveProcessor` can be initialized with a `:comments` key that holds an array of characters that denote a comment. For example the coffeescript language uses `#` as a comment. We could apply directive support to coffeescript files by registering:

```ruby
Sprockets.register_preprocessor 'text/coffeescript', DirectiveProcessor.new(comments: ["#", ["###", "###"]])
```

## Register Mime Types

You can add new mime-types to Sprockets by using the `register_mime_type` method. For example:

```ruby
Sprockets.register_mime_type 'application/json', extensions: ['.json'], charset: :unicode
Sprockets.register_mime_type 'application/ruby', extensions: ['.rb']
```

The first method is the mime-type of the object. The `:extensions` key passed to the second argument contains an array of all the extensions for the given mime type. An optional charset can be registered. This should only be used for text based mimetypes.

Your extension may have multiple parts for example some people use `.coffee.js` when this file type is used, we do not wish it to process as javascript first and then as coffee script so we register this entire extension:


```ruby
Sprockets.register_mime_type 'text/coffeescript', extensions: ['.coffee', '.js.coffee']
```

### Metadata Keys

While you can store arbitrary keys in the metadata returned by your extension, there are some with special meaning and
uses inside of Sprockets. More may be added in the future.

Anything you add to the metadata will be stored in the Sprockets cache for the asset.

- map: This key contains a source map for the asset.

A source map is a way to tell a browser how to map a generated file to an original for example if you write a
CoffeeScript file, Sprockets will generate a JavaScript file which is what the browser will see. If you need to debug
this javascript file it helps if you know where the in your original CoffeeScript file the generated JavaScript code
came from. The source map tells the browser how to map from a generated file to an original.

Sprockets expects an array of hashes for this map. Each hash must have a `:source` key, the name of the original file
from which generated content came.

```ruby
return {data: data, map: [{ source: "original.coffee", # ... }]}
```

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

## Supporting All Versions of Sprockets in Processors

If you are extending sprockets you may want to support all current major versions of sprockets (2, 3, and 4). The processor interface was deprecated from Sprockets 2 and a legacy shim was put into Sprockets 3. Now that Sprockets 4 is out that shim no longer is active, so you'll need to update your gem to either only use the new interface or use both interfaces.

As a recap Sprockets 2 let you register a processor with a class that would be instantiated and the method `render` called on it you can [view the calling code in Sprockets 2.x](https://github.com/rails/sprockets/blob/2199a6012cc2b9cdbcbc0049361e5ee02770dff0/lib/sprockets/context.rb#L194-L202). It may have looked like this:


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

You can also pass a block to both 2.x and 3.x+, however the number of args the method takes has changed so it's very hard to do that method and support multiple processor interfaces.

This `render` interface is deprecated, instead you should use the `call` interface. Whatever you pass to the processor can have a `call` method, it does not need to be a class.


```ruby
# Sprockets 3.x+ interface

module MySprocketsExtension
  def self.call(input)
    # code
  end
end

require 'sprockets/processing'
extend Sprockets::Processing

register_preprocessor 'text/css', MySprocketsExtension
```

Some of the hash keys have changed between sprockets 3 and 4. For example in Sprockets 3 the filename is passed in the
key `:filename` while in Sprockets 4 it is `:source_path`. You'll want to support both of them you can do something like
this in your code

```ruby
# Sprockets 3.x+ interface

module MySprocketsExtension
  def self.call(input)
    filename = input[:source_path] || input[:filename]
    # code
  end
end
```

Okay so if you want 2, 3, and 4 to work you can pass in a class that also has a `call` method on it. To see how this can be done you can reference this [autoprefixer-rails pull request](https://github.com/ai/autoprefixer-rails/pull/85). The shorthand code looks something like this:

```ruby
# Sprockets 2.x & 3.x+ interface

class MySprocketsExtension
  def initialize(filename, &block)
    @filename = filename
    @source   = block.call
  end

  def render(variable, empty_hash_wtf)
    self.class.run(@filename, @source)
  end

  def self.run(filename, source)
    # do somethign with filename and source
  end

  def self.call(input)
    filename = input[:source_path] || input[:filename]
    source   = input[:data]
    run(filename, source)
  end
end

require 'sprockets/processing'
extend Sprockets::Processing

register_preprocessor 'text/css', MySprocketsExtension
```

This way you're passing in an object that responds to 3.x's `call` interface and 2.x's `new.render` interface. In generally we're recommending people not use Sprockets 2.x and that they upgrade to Sprockets 3+. If it's easier on you, you can rev a major version and only support the new interface.


## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).

