# Building an Asset Processing Framework

This guide is for using a Sprockets::Environment to process assets. You would use this class directly if you were building a feature similar to Rail's asset pipeline. If you aren't building an asset processing frameworks, you will want to refer to the [End User Asset Generation](end_user_asset_generation.md) guide instead. For a reference use of `Sprockets::Environemnt` see [sprockets-rails](github.com/rails/Sprockets-rails).

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

You can disable this behavior `Sprockets::Environemnt#gzip=` to something falsey for example:

```ruby
env = Sprockets::Environment.new(".")
env.gzip = false
```

## WIP

This guide is a work in progress. There are many different groups of people who interact with Sprockets. Some only need to know directive syntax to put in their asset files, some are building features like the Rails asset pipeline, and some are plugging into Sprockets and writing things like preprocessors. The goal of these guides are to provide task specific guidance to make the expected behavior explicit. If you are using Sprockets and you find missing information in these guides, please consider submitting a pull request with updated information.

These guides live in [guides](/guides).
