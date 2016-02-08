# Extending Sprockets

Sprockets can use custom processors, compressors, and directives. This document is intended for library authors who want to extend Sprockets functionality.

## Types of Extensions

Sprockets supports a few different ways to extend functionality.

- preprocessors
- transformers
- compressors

For a detailed explantation of each see the respective sections below.

Sprockets ships with a number of built in processors, transformers and compressors. You can see all the defaults registered in `lib/sprockets.rb`.

## Preprocesors

A preprocessor is called as an asset is loaded. Generally preprocessors take in a raw file and convert its contents. For example the `DirectiveProcessor` is the processor that is responsible for reading in the Sprockets directives such as:

```js
//= require "foo"
```

It will then load in the `foo` file and add its contents to the original file.

### Preprocessor Interface

A preprocessor is expected to respond to `call()` and it accepts a hash of file contents. It is expected to return a hash that includes a `:data` key. The value returned in the `:data` key will be used as the contents for the file. Any other keys returned will be stored in the `:metadata` hash of an asset. For example, this result:

```ruby
class HelloWorldProcessor
  def call(input)
    return { data: input[:data] + "\n'hello world'" }
  end
end
```

Would apppend the string `'hello world'` on a new line to any asset.

For Sprockets to call the processor it must be registered. If we wanted this processor to be called with any javascript files we would use the javascript mime type `application/javascript` and pass in the object that responds to call, in this case an instance of the HelloWorldProcessor class:

```ruby
Sprockets.register_preprocessor('application/javascript', HelloWorldProcessor.new)
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

A compressor takes in an asset, and returns a smaller version of that asset. For example the uglifier compressor takes in a javascript file, it then removes the whitespace and applies other space saving techniques and returns a smaller javascript source. It must respond to `call` and return a `:data` key in a hash similar to a preprocessor. You can register a compressor like this:

```ruby
Sprockets.register_compressor 'application/javascript', :uglify, UglifierCompressor
```

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

While you can store arbitrary keys in the metadata returned by your extension, there are some with special meaning and uses inside of Sprockets. More may be added in the future.

Anything you add to the metadata will be stored in the Sprockets cache for the asset.

- map: This key contains a source map for the asset

A source map is a way to tell a browser how to map a generated file to an original for example if you write a coffeescript file, Sprockets will generate a javascript file which is what the browser will see. If you need to debug this javascript file it helps if you know where the in your original coffeescript file the generated javascript code came from. The source map tells the browser how to map from a generated file to an original

Sprockets expects an array of hashes for this map. Each hash must have a `:source` key, the name of the original file from which generated content came.

```ruby
return {data: data, map: [{ source: "original.coffee", # ... }]}
```

- charset: This key contains the mime charset for an asset

A charset is the encoding for text based assets. If you do not specify a charset then one will be automatically assigned by sprockets based on the encoding type of the contents returned in the `:data` key. Normally you want that, the only time you don't want that is if you're working with binary data, or data you don't want to be compressed. If sprockets sees a `charset` then it will think that the contents of the file are text and can be compressed via GZIP. You can avoid this by setting the field manually

```ruby
return { data: data, charset: nil }
```


WIP the format of the source map may be subject to change before 4.0 is released. Currently it takes a `:original` and `:generated` key which each hold an array of line and column numbers. Line numbers are 1 indexed column numbers are 0 indexed. The first character of a file will always be `[1,0]`.

- WIP - other metadata keys


## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).
