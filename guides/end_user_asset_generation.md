# End User Asset Generation

This guide is for those using Sprockets through an interface similar to the Rails asset pipeline. It will talk about end user interfaces. If you are not the end user, but instead a tools developer who is building an asset processing framework, see [building an asset processing framework](building_an_asset_processing_framework.md).

## What is Sprockets?

Sprockets is a Ruby library for compiling and serving web assets.
It features declarative dependency management for JavaScript and CSS
assets, as well as a preprocessor pipeline that allows you to
write assets in languages like CoffeeScript, Sass and SCSS.

## Behavior Overview

You can interact through Sprockets primarily through directives and file extensions. This section covers how to use each of these things, and the defaults that ship with Sprockets.

Since you are likely using Sprockets through another framework (like the Rails asset pipeline), there will configuration options you can toggle that will change behavior such as what directories or files get compiled. For that documentation you should see your framework's documentation.

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

Here is a list of the available directives

- require
- require_self
- require_tree
- require_directory
- depend
- depend_on_asset
- stub
- link
- link_directory
- link_tree

You can see what each of these does below

### Specifying Processors through File Extensions

Sprockets uses the filename extensions to determine what processors to run on your file and in what order. For example if you have a file:

```
application.scss
```

Then Sprockets will by default run the sass processor (which implements scss). The output file will be converted to css.

You can specify multiple processors by specifying multiple file extensions. For example you can use Ruby's [ERB template language](http://ruby-doc.org/stdlib-2.2.3/libdoc/erb/rdoc/ERB.html) to embed content in your doc before running the sass processor. To accomplish this you would need to name your file

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

```
//= require jquery
//= require alpha
//= require beta
```

Or you can use index files to proxy your folders

### Index files are proxies for folders

In Sprockets index files such as `index.js` or `index.css` files inside of a folder will generate a file with the folder's name. So if you have a `foo/index.js` file it will compile down to `foo.js`. This is similar to NPM's behavior of using [folders as modules](https://nodejs.org/api/modules.html#modules_folders_as_modules). It is also somewhat similar to the way that a file in `public/my_folder/index.html` can be reached by a request to `/my_folder`. This means that you cannot directly use an index file. For example this would not work:

```
<%= asset_path("foo/index.js") %>
```

Instead you would need to use:

```
<%= asset_path("foo.js") %>
```

Why would you want to use this behavior?  It is common behavior where you might want to include an entire directory of files in a top level JavaScript. You can do this in Sprockets using `require_tree .`

```
//= require_tree .
```

This has the problem that files are required alphabetically. If your directory has `jquery-ui.js` and `jquery.min.js` then Sprockets will require `jquery-ui.js` before `jquery` is required which won't work (because jquery-ui depends on jquery). Previously the only way to get the correct ordering would be to rename your files, something like `0-jquery-ui.js`. Instead of doing that you can use an index file.

For example, if you have an `application.js` and want all the files in the `foo/` folder you could do this:

```
//= require foo.js
```

Then create a file `foo/index.js` that requires all the files in that folder in any order you want:

```
//= require foo.min.js
//= require foo-ui.js
```

Now in your `application.js` will correctly load the `foo.min.js` before `foo-ui.js`. If you used `require_tree` it would not work correctly.


## Default Directives

TODO: add description of each of the directives

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

### Gzip

By default when Sprockets generates a compiled asset file it will also produce a gzipped copy of that file. Sprockets only gzips non-binary files such as CSS, javascript, and SVG files.

For example if Sprockets is generating

```
application-12345.css
```

Then it will also generate a compressed copy in

```
application-12345.css.gz
```

This behavior can be disabled, refer to your framework specific documentation.

## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).
