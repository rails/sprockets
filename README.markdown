Sprockets
=========

[http://getsprockets.org/](http://getsprockets.org/)

Sprockets is a Ruby library that preprocesses and concatenates JavaScript source files. It takes any number of source files and preprocesses them line-by-line in order to build a single concatenation. Specially formatted lines act as directives to the Sprockets preprocessor, telling it to require the contents of another file or library first or to provide a set of asset files (such as images or stylesheets) to the document root. Sprockets attempts to fulfill required dependencies by searching a set of directories called the load path.


## Why use Sprockets?

**Extract reusable code and share it across multiple web sites or applications.** Sprockets makes it easy to extract JavaScript plugins from your site or application and share them across your portfolio. Use your SCM to check out plugin repositories directly into your site or application. Then tell Sprockets to add the plugins to your load path. Support for asset provisioning lets you bundle CSS and images with JavaScript plugins, too.

**Speed up your site by automatically concatenating JavaScript into a single file for production.** Concatenating your site's JavaScript means all your source code is cached in the browser on the first hit. It also means you reduce the number of HTTP requests necessary to load a single page. When combined with gzip compression on the web server, concatenation is the fastest way to serve JavaScript to your users.

**Organize your JavaScript source code into multiple commented files and directories.** Finally, an end to navigating long, difficult-to-maintain JavaScript source files. With Sprockets, JavaScript source code can live anywhere on your system, even outside your site's or application's document root. You're free to split source code up into multiple files and organize those files into directories during development. You can also add as many comments as you want&mdash;they'll be stripped from the resulting output.

**Use bleeding-edge framework and library code in your application.** If you use and contribute to open-source JavaScript frameworks and libraries that use Sprockets, like [Prototype](http://www.prototypejs.org/) and [script.aculo.us](http://script.aculo.us/), the build processes for those scripts can be integrated directly into your application. That makes it possible to track the latest development versions of your framework and library dependencies by adding their repositories to your application's Sprockets load path.

**Sprockets is compatible with the PDoc JavaScript documentation system and the JavaScript framework of your choice.** If you document your JavaScript source code with [PDoc](http://www.pdoc.org/), Sprockets will automatically strip documentation comments from the resulting concatenated output. You can use any JavaScript framework you like in your site or application&mdash;Sprockets is framework-agnostic.


## Installing Sprockets

Sprockets is written in Ruby and has no runtime dependencies apart from the Ruby standard library. You can install it with RubyGems:

    $ gem install --remote sprockets
    
This will also install the `sprocketize` command-line utility.


## Sprocketizing your source code

Sprockets takes any number of _source files_ and preprocesses them line-by-line in order to build a single _concatenation_. Specially formatted lines act as _directives_ to the Sprockets preprocessor, telling it to _require_ the contents of another file or library first or to _provide_ a set of asset files to the document root. Sprockets attempts to fulfill required dependencies by searching a set of directories called the _load path_.

### How Sprockets handles comments

Use single-line <nobr>(`//`)</nobr> comments in JavaScript source files for comments that don't need to appear in the resulting concatenated output. Use multiple-line <nobr>(`/* ... */`)</nobr> comments for comments that _should_ appear in the resulting concatenated output, like copyright notices or descriptive headers. PDoc <nobr>(`/** ... **/`)</nobr> documentation comments will not be included in the resulting concatenation.

Comments beginning with `//=` are treated by Sprockets as _directives_. Sprockets currently understands two directives, `require` and `provide`.

### Specifying dependencies with the `require` directive

Use the `require` directive to tell Sprockets that another JavaScript source file should be inserted into the concatenation before continuing to preprocess the current source file. If the specified source file has already been required, Sprockets ignores the directive.

The format of a `require` directive determines how Sprockets looks for the dependent source file. If you place the name of the source file in angle brackets:

    //= require <prototype>
    
Sprockets will search your load path, in order, for a file named `prototype.js`, and begin preprocessing the first match it finds. (An error will be raised if a matching file can't be found.) If you place the name of the source file in quotes:

    //= require "date_helper"
    
Sprockets will _not_ search the load path, but will instead look for a file named `date_helper.js` in the same directory as the current source file. In general, it is a good idea to use quotes to refer to related files, and angle brackets to refer to packages, libraries, or third-party code that may live in a different location.

You can refer to files in subdirectories with the `require` directive. For example:

    //= require <behavior/hover_observer>
    
Sprockets will search the load path for a file named `hover_observer.js` in a directory named `behavior`.

### Bundling assets with the `provide` directive

Sometimes it is necessary to include associated stylesheets, images, or even HTML files with a JavaScript plugin. Sprockets lets you specify that a JavaScript source file depends on a set of assets, and offers a routine for copying all dependent assets into the document root.

The `provide` directive tells Sprockets that the current source file depends on the set of assets in the named directory. For example, say you have a plugin with the following directory structure:

    plugins/color_picker/assets/images/color_picker/arrow.png
    plugins/color_picker/assets/images/color_picker/circle.png
    plugins/color_picker/assets/images/color_picker/hue.png
    plugins/color_picker/assets/images/color_picker/saturation_and_brightness.png
    plugins/color_picker/assets/stylesheets/color_picker.css
    plugins/color_picker/src/color.js
    plugins/color_picker/src/color_picker.js
    
Assume `plugins/color_picker/src/` is in your Sprockets load path. `plugins/color_picker/src/color_picker.js` might look like this:
  
    //= require "color"
    //= provide "../assets"
    
When `<color_picker>` is required in your application, its `provide` directive will tell Sprockets that all files in the `plugins/color_picker/assets/` directory should be copied into the web server's document root.

### Inserting string constants with `<%= ... %>`

You may need to parameterize and insert constants into your source code. Sprockets lets you define such constants in a special file called `constants.yml` that lives in your load path. This file is formatted as a [YAML](http://yaml.org/spec/1.2/) hash.

Continuing the `color_picker` example, assume `plugins/color_picker/src/constants.yml` contains the following:

    COLOR_PICKER_VERSION: 1.0.0
    COLOR_PICKER_AUTHOR: Sam Stephenson <sam@example.org>
    
The constants are specified in a single place, and you can now insert them into your source code without repetition:

    /* Color Picker plugin, version <%= COLOR_PICKER_VERSION %>
     * (c) 2009 <%= COLOR_PICKER_AUTHOR %>
     * Distributed under the terms of an MIT-style license */
     
    var ColorPicker = {
      VERSION: '<%= COLOR_PICKER_VERSION %>',
      ...
    };

The resulting concatenated output will have the constant values substituted in place:

    /* Color Picker plugin, version 1.0.0
     * (c) 2009 Sam Stephenson <sam@example.org>
     * Distributed under the terms of an MIT-style license */
 
    var ColorPicker = {
      VERSION: '1.0.0',
      ...
    };
    
Constants share a global namespace, so you can refer to constants defined anywhere in your load path. If a constant is not found, Sprockets raises an error and halts further preprocessing.


## Using Sprockets

Sprockets is distributed as a Ruby library. It comes with a command-line tool called `sprocketize` for generating concatenations and installing provided assets. You can also use the `sprockets-rails` plugin to sprocketize your Rails application. A simple CGI is bundled with Sprockets for use in other environments.

### Sprockets as a Ruby library

The simplest way to use Sprockets from Ruby is with the `Sprockets::Secretary` class. A `Secretary` handles the job of setting up a Sprockets environment, creating a preprocessor, loading your application's source files, and generating the resulting concatenation.

You can pass the following options to `Sprockets::Secretary.new`:

* `:root` - Specifies the Sprockets root, or the base location for all directories specified in the load path and source files required by the preprocessor. Defaults to `"."` (the current working directory).
* `:asset_root` - Specifies the application's document root, or the directory from which the web server serves its files.
* `:load_path` - An ordered array of directory names (either absolute paths, or paths relative to the Sprockets root) where Sprockets will search for required JavaScript dependencies.
* `:source_files` - An ordered array of JavaScript source files (either absolute paths, or paths relative to the Sprockets root) that Sprockets will require one-by-one to build the resulting concatenation.
* `:expand_paths` - Specifies whether or not Sprockets will expand filenames in the `load_path` and `source_files` arrays according to shell glob rules (e.g. `:load_path => ["vendor/sprockets/*/src"]` or `:source_files => ["app/javascripts/**/*.js"]`). Defaults to `true`; set it to `false` if you do _not_ want shell expansion applied to paths.

Once you have a `Secretary` object, you can call its `concatenation` method to get a `Sprockets::Concatenation` object back. You can also call its `install_assets` method to install provided assets into the directory specified by the `:asset_root` option.

Example:

    secretary = Sprockets::Secretary.new(
      :asset_root   => "public",
      :load_path    => ["vendor/sprockets/*/src", "vendor/plugins/*/javascripts"],
      :source_files => ["app/javascripts/application.js", "app/javascripts/**/*.js"]
    )
    
    # Generate a Sprockets::Concatenation object from the source files
    concatenation = secretary.concatenation
    # Write the concatenation to disk
    concatenation.save_to("public/sprockets.js")
    
    # Install provided assets into the asset root
    secretary.install_assets
    
You can ask the `Secretary` for the most recent last-modified time of all the source files that make up the concatenation with the `source_last_modified` method. Use this in conjunction with the `reset!` method to reuse a `Secretary` instance across multiple requests and only regenerate concatenations when the source file has changed.

### Using `sprocketize` from the command line

The `sprocketize` command is a simple wrapper around `Sprockets::Secretary`. It takes any number of source files (specified as command-line arguments) and preprocesses them according to the options you pass. Then it prints the resulting concatenation to standard output, where it can be redirected to a file or piped to another program for further processing.

You can pass the following command-line options to `sprocketize`:

    -C, --directory=DIRECTORY    Change to DIRECTORY before doing anything
    -I, --include-dir=DIRECTORY  Adds the directory to the Sprockets load path
    -a, --asset-root=DIRECTORY   Copy provided assets into DIRECTORY
    -h, --help                   Shows this help message
    -v, --version                Shows version

Example:

    $ sprocketize -I app/javascripts \
                  -I vendor/sprockets/prototype/src \
                  -I vendor/sprockets/color_picker/src \
                  --asset-root=public \
                  app/javascripts/*.js > public/sprockets.js

### Using the `sprockets-rails` plugin in your Rails application

The [`sprockets-rails`](http://github.com/sstephenson/sprockets-rails/tree/master) plugin (distributed separately) sets up your Rails application for use with Sprockets. To install it, first install the `sprockets` RubyGem, then check out a copy of the `sprockets-rails` repository into your `vendor/plugins/` directory. When you run the bundled `install.rb` script, `sprockets-rails` will create two new directories in your application and copy a configuration file into your `config/` directory.

`sprockets-rails` includes a controller named `SprocketsController` that renders your application's Sprockets concatenation. When caching is enabled, e.g. in production mode, `SprocketsController` uses Rails page caching to save the concatenated output to `public/sprockets.js` the first time it is requested. When caching is disabled, e.g. in development mode, `SprocketsController` will render a fresh concatenation any time a source file changes.

To source Sprockets' JavaScript concatenation from your HTML templates, use the provided `sprockets_include_tag` helper.

`sprockets-rails` also includes a set of Rake tasks for generating the concatenation (`rake sprockets:install_script`) and installing provided assets (`rake sprockets:install_assets`). Run `sprockets:install_assets` any time you add or update a Sprockets plugin in your application. Add `sprockets:install_script` as a [Capistrano](http://www.capify.org/) post-deploy hook to generate the Sprockets concatenation on your servers automatically at deploy time.

Here's a walkthrough of the installation process:

1. `gem install --remote sprockets`

2. `script/plugin install git://github.com/sstephenson/sprockets-rails.git`

    You now have `app/javascripts/` and `vendor/sprockets/` directories in your application, as well as a `config/sprockets.yml` file.

3. Edit your `config/routes.rb` file to add routes for `SprocketsController`:

        ActionController::Routing::Routes.draw do |map|
          # Add the following line:
          SprocketsApplication.routes(map) 
          ...
        end

4. Move your JavaScript source files from `public/javascripts/` into `app/javascripts/`. All files in all subdirectories of `app/javascripts/` will be required by Sprockets in alphabetical order, with the exception of `app/javascripts/application.js`, which is required _before any other file_. (You can change this behavior by editing the `source_files` line of `config/sprockets.yml`.)

5. Adjust your HTML templates to call `<%= sprockets_include_tag %>` instead of `<%= javascript_include_tag ... %>`.

Once `sprockets-rails` is installed, you can check out Sprockets plugins into the `vendor/sprockets/` directory. By default, `sprockets-rails` configures Sprockets' load path to search `vendor/sprockets/*/src/`, as well as `vendor/plugins/*/javascripts/`. This means that the `javascripts/` directories of Rails plugins are automatically installed into your Sprockets load path.

### Using the bundled Sprockets CGI script

Sprockets comes with a simple CGI script for serving JavaScript outside of a Ruby environment. You can find it, along with brief documentation and installation instructions, as `ext/nph-sprockets.cgi` in your copy of the Sprockets source code. (If you installed Sprockets with RubyGems, you can find the location of the Sprockets source code with the `gem which sprockets` command.)


## Contributing to Sprockets

The Sprockets source code is hosted on [GitHub](http://github.com/). Check out a working copy with [Git](http://git-scm.com/):

    $ git clone git://github.com/sstephenson/sprockets.git
    
You can fork the Sprockets project on GitHub, commit your changes, and [send a pull request](http://github.com/guides/pull-requests) if you'd like your feature or bug fix to be considered for the next release. Please make sure to update the unit tests as well.

### Reporting bugs

If you find a bug in Sprockets and aren't feeling motivated to fix it yourself, you can file a ticket at the [Sprockets Lighthouse project](http://prototype.lighthouseapp.com/projects/8888-sprockets).


## License

Copyright &copy; 2009 Sam Stephenson.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
