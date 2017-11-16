# Building an Asset Processing Framework

This guide is for using a Sprockets::Environment to process assets. You would use this class directly if you were building a feature similar to Rail's asset pipeline. If you aren't building an asset processing frameworks, you will want to refer to the [End User Asset Generation](end_user_asset_generation.md) guide instead. For a reference use of `Sprockets::Environemnt` see [sprockets-rails](http://github.com/rails/Sprockets-rails).

## Understanding the Sprockets Environment

You'll need an instance of the `Sprockets::Environment` class to
access and serve assets from your application. Under Rails 4.0 and
later, `Rails.application.assets` is a preconfigured
`Sprockets::Environment` instance. For Rack-based applications, create
an instance in `config.ru`.

The Sprockets `Environment` has methods for retrieving and serving
assets, manipulating the load path, and registering processors. It is
also a Rack application that can be mounted at a URL to serve assets
over HTTP.

### The Load Path

The *load path* is an ordered list of directories that Sprockets uses
to search for assets.

In the simplest case, a Sprockets environment's load path will consist
of a single directory containing your application's asset source
files. When mounted, the environment will serve assets from this
directory as if they were static files in your public root.

The power of the load path is that it lets you organize your source
files into multiple directories -- even directories that live outside
your application -- and combine those directories into a single
virtual filesystem. That means you can easily bundle JavaScript, CSS
and images into a Ruby library or [Bower](http://bower.io) package and import them into your application.

#### Manipulating the Load Path

To add a directory to your environment's load path, use the
`append_path` and `prepend_path` methods. Directories at the beginning
of the load path have precedence over subsequent directories.

``` ruby
environment = Sprockets::Environment.new
environment.append_path 'app/assets/javascripts'
environment.append_path 'lib/assets/javascripts'
environment.append_path 'vendor/assets/bower_components'
```

In general, you should append to the path by default and reserve
prepending for cases where you need to override existing assets.

### Accessing Assets

Once you've set up your environment's load path, you can mount the
environment as a Rack server and request assets via HTTP. You can also
access assets programmatically from within your application.

#### Logical Paths

Assets in Sprockets are always referenced by their *logical path*.

The logical path is the path of the asset source file relative to its
containing directory in the load path. For example, if your load path
contains the directory `app/assets/javascripts`:

<table>
  <tr>
    <th>Logical path</th>
    <th>Source file on disk</th>
  </tr>
  <tr>
    <td>application.js</td>
    <td>app/assets/javascripts/application.js</td>
  </tr>
  <tr>
    <td>models/project.js</td>
    <td>app/assets/javascripts/models/project.js</td>
  </tr>
  <tr>
    <td>hello.js</td>
    <td>app/assets/javascripts/hello.coffee</td>
  </tr>
</table>

> Note: For assets that are compiled or transpiled, you want to specify the extension that you want, not the extension on disk. For example we specified `hello.js` even if the file on disk is a coffeescript file, since the asset it will generate is javascript.

In this way, all directories in the load path are merged to create a
virtual filesystem whose entries are logical paths.

#### Serving Assets Over HTTP

When you mount an environment, all of its assets are accessible as
logical paths underneath the *mount point*. For example, if you mount
your environment at `/assets` and request the URL
`/assets/application.js`, Sprockets will search your load path for the
file named `application.js` and serve it.

Under Rails 4.0 and later, your Sprockets environment is automatically
mounted at `/assets`. If you are using Sprockets with a Rack
application, you will need to mount the environment yourself. A good
way to do this is with the `map` method in `config.ru`:

``` ruby
require 'sprockets'
map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'app/assets/javascripts'
  environment.append_path 'app/assets/stylesheets'
  run environment
end

map '/' do
  run YourRackApp
end
```

#### Accessing Assets Programmatically

You can use the `find_asset` method (aliased as `[]`) to retrieve an
asset from a Sprockets environment. Pass it a logical path and you'll
get a `Sprockets::Asset` instance back:

``` ruby
environment['application.js']
# => #<Sprockets::Asset ...>
```

Call `to_s` on the resulting asset to access its contents, `length` to
get its length in bytes, `mtime` to query its last-modified time, and
`filename` to get its full path on the filesystem.

## Using Processors

Asset source files can be written in another format, like SCSS or CoffeeScript,
and automatically compiled to CSS or JavaScript by Sprockets. Processors that
convert a file from one format to another are called *transformers*.

### Invoking Ruby with ERB

Sprockets provides an ERB engine for preprocessing assets using
embedded Ruby code. Append `.erb` to a CSS or JavaScript asset's
filename to enable the ERB engine.

Ruby code embedded in an asset is evaluated in the context of a
`Sprockets::Context` instance for the given asset. Common uses for ERB
include:

- embedding another asset as a Base64-encoded `data:` URI with the
  `asset_data_uri` helper
- inserting the URL to another asset, such as with the `asset_path`
  helper provided by the Sprockets Rails plugin
- embedding other application resources, such as a localized string
  database, in a JavaScript asset via JSON
- embedding version constants loaded from another file

See the [Helper Methods](lib/sprockets/context.rb) section for more information about
interacting with `Sprockets::Context` instances via ERB.

## Managing and Bundling Dependencies

You can create *asset bundles* -- ordered concatenations of asset
source files -- by specifying dependencies in a special comment syntax
at the top of each source file.

Sprockets reads these comments, called *directives*, and processes
them to recursively build a dependency graph. When you request an
asset with dependencies, the dependencies will be included in order at
the top of the file.

### The Directive Processor

Sprockets runs the *directive processor* on each CSS and JavaScript
source file. The directive processor scans for comment lines beginning
with `=` in comment blocks at the top of the file.

``` js
//= require jquery
//= require jquery-ui
//= require backbone
//= require_tree .
```

The first word immediately following `=` specifies the directive
name. Any words following the directive name are treated as
arguments. Arguments may be placed in single or double quotes if they
contain spaces, similar to commands in the Unix shell.

**Note**: Non-directive comment lines will be preserved in the final
  asset, but directive comments are stripped after
  processing. Sprockets will not look for directives in comment blocks
  that occur after the first line of code.

#### Supported Comment Types

The directive processor understands comment blocks in three formats:

``` css
/* Multi-line comment blocks (CSS, SCSS, JavaScript)
 *= require foo
 */
```

``` js
// Single-line comment blocks (SCSS, JavaScript)
//= require foo
```

``` coffee
# Single-line comment blocks (CoffeeScript)
#= require foo
```

## Processor Interface

Sprockets 2.x was originally designed around [Tilt](https://github.com/rtomayko/tilt)'s engine interface. However, starting with 3.x, a new interface has been introduced deprecating Tilt.

Similar to Rack, a processor is any "callable" (an object that responds to `call`). This may be a simple Proc or a full class that defines a `def self.call(input)` method. The `call` method accepts an `input` Hash and returns a Hash of metadata.

Also see [`Sprockets::ProcessorUtils`](https://github.com/rails/sprockets/blob/master/lib/sprockets/processor_utils.rb) for public helper methods.

## Gzip

By default when Sprockets generates a compiled asset file it will also produce a gzipped copy of that file. Sprockets only gzips non-binary files such as CSS, JavaScript, and SVG files.

For example if Sprockets is generating

```
application-12345.css
```

Then it will also generate a compressed copy in

```
application-12345.css.gz
```

You can disable this behavior `Sprockets::Environment#gzip=` to something falsey for example:

```ruby
env = Sprockets::Environment.new(".")
env.gzip = false
```

By default Sprockets uses zlib to generate the compiled asset, you can use zopfli by installing the zopfli gem and then telling Sprockets to compile assets with it:

```ruby
env = Sprockets::Environment.new(".")
env.gzip = :zopfli
```

Setting to any other truthy value will enable zlib compression.

## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).
