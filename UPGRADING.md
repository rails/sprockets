# Guide to upgrading from Sprockets 2.x to 3.x

Even though its a major release, Sprockets 3.x should be fairly API compatible
with 2.x unless explicitly note in the CHANGELOG. For the most part, the
application facing APIs have remained the same with the majority of the changes
at the extension layer. So you shouldn't have to change much application code,
but you should verify that all the sprockets extension gems you are using are
compatible with 3.x.

## Application Changes

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
/* A comment directive or erb call can we used to declare a link relationship */
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
