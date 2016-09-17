# End User Asset Generation

This guide is for those using Sprockets through an interface similar to the Rails asset pipeline. It will talk about end user interfaces. If you are not the end user, but instead a tools developer who is building an asset processing framework, see [building an asset processing framework](building_an_asset_processing_framework.md).

## What is Sprockets?

Sprockets is a Ruby library for compiling and serving web assets.
It features declarative dependency management for JavaScript and CSS assets, as well as a preprocessor pipeline that allows you to write assets in languages like CoffeeScript, Sass and SCSS.

## Behavior Overview

You can interact through Sprockets primarily through directives and file extensions. This section covers how to use each of these things, and the defaults that ship with Sprockets.

Since you are likely using Sprockets through another framework (such as the [the Rails asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html)), there will be configuration options you can toggle that will change behavior such as what directories or files get compiled. For that documentation you should see your framework's documentation.

### Directives

Directives are special comments in your asset file and the main way of interacting with processors. What kind of interactions? You can use these directives to tell Sprockets to load other files, or specify dependencies on other assets.

For example, let's say you have custom JavaScript that you've written. You put this javascript in a file called `beta.js`. The javascript makes heavy use of jQuery, so you need to load that before your code executes. You could add this directive to the top of `beta.js`:

```js
//= require jquery

$().ready({
  // my custom code here
})
```

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

> Note: Directives are only processed if they come before any application code. Once you have a line that does not include a comment or whitespace then Sprockets will stop looking for directives. If you use a directive outside of the "header" of the document it will not do anything, and won't raise any errors.

Here is a list of the available directives:

- [`require`](#require)
- [`require_self`](#require_self)
- [`require_tree`](#require_tree)
- [`require_directory`](#require_directory)
- [`depend`](#depend)
- [`depend_on_asset`](#depend_on_asset)
- [`stub`](#stub)
- [`link`](#link)
- [`link_directory`](#link_directory)
- [`link_tree`](#link_directory)

You can see what each of these does below.

### Specifying Processors through File Extensions

Sprockets uses the filename extensions to determine what processors to run on your file and in what order. For example if you have a file:

```
application.scss
```

Then Sprockets will by default run the sass processor (which implements scss). The output file will be converted to css.

You can specify multiple processors by specifying multiple file extensions. For example you can use Ruby's [ERB template language](http://ruby-doc.org/stdlib-2.3.0/libdoc/erb/rdoc/ERB.html) to embed content in your doc before running the sass processor. To accomplish this you would need to name your file

```
application.scss.erb
```

Processors are run from right to left, so in the above example the processor associated with `erb` will be run before the processor associated with `scss` extension.

For a description of the processors that Sprockets has by default see the "default processors" section below. Other libraries may register additional processors.

## File Order Processing

By default files are processed in alphabetical order. This behavior can impact your asset compilation when one asset needs to be loaded before another.

For example if you have an `application.js` and it loads another directory

```js
//= require_directory my_javascript
```

The files in that directory will be loaded in alphabetical order. If the directory looks like this:

```sh
$ ls -1 my_javascript/

alpha.js
beta.js
jquery.js
```

Then `alpha.js` will be loaded before either of the other two. This can be a problem if `alpha.js` uses jquery. For this reason it is not recommend to use `require_directory` with files that are ordering dependent. You can either require individual files manually:

```js
//= require jquery
//= require alpha
//= require beta
```

Or you can use index files to proxy your folders

### Index files are proxies for folders

In Sprockets index files such as `index.js` or `index.css` files inside of a folder will generate a file with the folder's name. So if you have a `foo/index.js` file it will compile down to `foo.js`. This is similar to NPM's behavior of using [folders as modules](https://nodejs.org/api/modules.html#modules_folders_as_modules). It is also somewhat similar to the way that a file in `public/my_folder/index.html` can be reached by a request to `/my_folder`. This means that you cannot directly use an index file. For example this would not work:

```erb
<%= asset_path("foo/index.js") %>
```

Instead you would need to use:

```erb
<%= asset_path("foo.js") %>
```

Why would you want to use this behavior?  It is common behavior where you might want to include an entire directory of files in a top level JavaScript. You can do this in Sprockets using `require_tree .`

```js
//= require_tree .
```

This has the problem that files are required alphabetically. If your directory has `jquery-ui.js` and `jquery.min.js` then Sprockets will require `jquery-ui.js` before `jquery` is required which won't work (because jquery-ui depends on jquery). Previously the only way to get the correct ordering would be to rename your files, something like `0-jquery-ui.js`. Instead of doing that you can use an index file.

For example, if you have an `application.js` and want all the files in the `foo/` folder you could do this:

```js
//= require foo.js
```

Then create a file `foo/index.js` that requires all the files in that folder in any order you want:

```js
//= require foo.min.js
//= require foo-ui.js
```

Now in your `application.js` will correctly load the `foo.min.js` before `foo-ui.js`. If you used `require_tree` it would not work correctly.


## Default Directives

### require

`require` *path* inserts the contents of the asset source file
specified by *path*. If the file is required multiple times, it will
appear in the bundle only once.

### require_self

`require_self` tells Sprockets to insert the body of the current
source file before any subsequent `require` directives.

### require_directory

`require_directory` *path* requires all source files of the same
format in the directory specified by *path*. Files are required in
alphabetical order.

### require_tree

`require_tree` *path* works like `require_directory`, but operates
recursively to require all files in all subdirectories of the
directory specified by *path*.

### depend_on

`depend_on` *path* declares a dependency on the given *path* without
including it in the bundle. This is useful when you need to expire an
asset's cache in response to a change in another file.

### depend_on_asset

`depend_on_asset` *path* works like `depend_on`, but operates
recursively reading the file and following the directives found. This is automatically implied if you use `link`, so consider if it just makes sense using `link` instead of `depend_on_asset`.

### stub

`stub` *path* excludes that asset and its dependencies from the asset bundle.
The *path* must be a valid asset and may or may not already be part
of the bundle. `stub` should only be used at the top level bundle, not
within any subdependencies.

### link

`link` *path* declares a dependency on the target *path* and adds it to a list
of subdependencies to automatically be compiled when the asset is written out to
disk.

### link_directory

`link_directory` *path* links all the files inside the directory specified by the *path*

### link_tree

`link_tree` *path* works like `link_directory`, but operates
recursively to link all files in all subdirectories of the
directory specified by *path*.

## Default Processors

TODO: add description of each of the processors

## Default Compressors

TODO:

## Output

This section details the default output of Sprockets. This may have been modified by the frameworks you're using, so you will want to verify behavior with their docs.

Processors and compressors will affect individual file output contents. Refer to the default processors and compressor section how processors for your asset may have modified your file.

### Manifest File

TODO: Explain contents, location, and name of a manifest file.

### Fingerprinting

TODO: Explain default fingerprinting/digest behavior

## Gzip Files

In many cases it is faster to serve a compressed (archived) file over a web request and have the client expand the file than it is to just serve the whole file. Many web browsers and clients support `gzip` by default. As a result By default when Sprockets generates a compiled asset file it will also produce a gzipped copy of that file on disk. Sprockets only gzips non-binary files such as CSS, javascript, and SVG files.

For example if Sprockets is generating

```
application-12345.css
```

Then it will also generate a compressed copy in

```
application-12345.css.gz
```

By default current verisons of Rails will serve your gzip file if you have `config.public_file_server.enabled = true`. If you are using another server such as NGINX or apache, you'll have to configure it to serve the gzip file from disk when appropriate.

### Gzip Behavior

To disable gzip behavior, refer to your framework specific documentation. For Rails it is:

```
config.assets.gzip = false
```

By default Sprockets generates gzip files using zlib which ships with the Ruby standard library. There are other algorithms you can use instead such as [zopfli](https://github.com/miyucy/zopfli). Usually you would use a different algorithm for either faster compression speed or a higher compression ratio, but the trade offs are application specific, so please benchmark and do not assume one application's default is good for your application.

To replace the compression algorithm set `gzip_compressor` to a new archiver, for example if you have the `zopfli` gem in your Gemfile you could use it:

```
config.assets.gzip_compressor = Sprockets::Utils::ZopfliArchiver
```

> Note if you have the `zopfli` gem loaded in your gemfile before Sprockets then Sprockets will use zopfli by default. Otherwise zlib, will be the default.

The gzip compressor must respond to a `call` method that takes three arguments, a file object, the file contents, and mtime of the original asset.

### Alternative Archive Formats

There are different algorithms that produce entirely new file formats such as [brotli](https://en.wikipedia.org/wiki/Brotli) (via the [brotli gem](https://github.com/miyucy/brotli)) generating `.br` files. In addition to generating the new file format, you'll also need to verify that the method you are using to serve assets from your webserver supports detecting and serving this new file type. At the time of writing Rails only supports serving the `gzip` format via `config.public_file_server.enabled `.

There is currently no standard interface for generating a non-gzip archive file from Sprockets. However you can use the gzip interface for generating custom archive formats:

```
original_compressor = config.assets.gzip_compressor

gzip_and_brotli_compressor = Proc.new do |file, contents, mtime|
  original_compressor.call(file, contents, mtime)
  gzip_file_name   = file.to_path
  brotli_file_name = gzip_file_name.gsub(/\.gz\z/, ".br")
  unless File.exist?(brotli_file_name)
    PathUtils.atomic_write(brotli_file_name) do |f|
      # write brotli file here
    end
  end
end

config.assets.gzip_compressor = gzip_and_brotli_compressor
```

Be very careful when doing this, make sure to call the original gzip compressor or you won't get `.gz` files generated. Your code may be called inside of a forked process or a thread, use `PathUtils.atomic_write` if writing to a file that was not passed in, and do not mutate global state.

## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).
