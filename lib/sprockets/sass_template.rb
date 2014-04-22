require 'sass'

module Sprockets
  # Template engine class for the SASS/SCSS compiler. Depends on the `sass` gem.
  #
  # For more infomation see:
  #
  #   https://github.com/nex3/sass
  #   https://github.com/rails/sass-rails
  #
  class SassTemplate
    # Internal: Defines default sass syntax to use. Exposed so the ScssTemplate
    # may override it.
    def self.syntax
      :sass
    end

    def self.call(*args)
      new.call(*args)
    end

    # Public: Initialize template with custom options.
    #
    # options - Hash
    #   cache_version - String custom cache version. Used to force a cache
    #                   change after code changes are made to Sass Functions.
    #
    def initialize(options = {})
      unless ::Sass::Script::Functions < SassFunctions
        # Install custom functions. It'd be great if this didn't need to
        # be installed globally, but could be passed into Engine as an
        # option.
        ::Sass::Script::Functions.send :include, SassFunctions
      end

      @cache_version = options[:cache_version]
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = {
        filename: input[:filename],
        syntax: self.class.syntax,
        cache_store: SassCacheStore.new(input[:cache], @cache_version),
        load_paths: input[:environment].paths,
        sprockets: {
          context: context,
          environment: input[:environment]
        }
      }

      engine = ::Sass::Engine.new(input[:data], options)
      css = engine.render

      # Track all imported files
      dependency_paths = engine.dependencies.map do |dependency|
        dependency.options[:filename]
      end

      context.to_hash.merge(data: css, dependency_paths: dependency_paths)
    end
  end

  class ScssTemplate < SassTemplate
    def self.syntax
      :scss
    end
  end

  # Internal: Cache wrapper for Sprockets cache adapter.
  class SassCacheStore < ::Sass::CacheStores::Base
    VERSION = '1'

    def initialize(cache, version)
      @cache, @version = cache, "#{VERSION}/#{version}"
    end

    def _store(key, version, sha, contents)
      @cache._set("#{@version}/#{version}/#{key}/#{sha}", contents)
    end

    def _retrieve(key, version, sha)
      @cache._get("#{@version}/#{version}/#{key}/#{sha}")
    end

    def path_to(key)
      key
    end
  end

  module SassFunctions
    def asset_path(path)
      Sass::Script::String.new(sprockets_context.asset_path(path.value), :string)
    end

    def asset_url(path)
      Sass::Script::String.new("url(" + sprockets_context.asset_path(path.value) + ")")
    end

    def image_path(path)
      Sass::Script::String.new(sprockets_context.image_path(path.value), :string)
    end

    def image_url(path)
      Sass::Script::String.new("url(" + sprockets_context.image_path(path.value) + ")")
    end

    def video_path(path)
      Sass::Script::String.new(sprockets_context.video_path(path.value), :string)
    end

    def video_url(path)
      Sass::Script::String.new("url(" + sprockets_context.video_path(path.value) + ")")
    end

    def audio_path(path)
      Sass::Script::String.new(sprockets_context.audio_path(path.value), :string)
    end

    def audio_url(path)
      Sass::Script::String.new("url(" + sprockets_context.audio_path(path.value) + ")")
    end

    def font_path(path)
      Sass::Script::String.new(sprockets_context.font_path(path.value), :string)
    end

    def font_url(path)
      Sass::Script::String.new("url(" + sprockets_context.font_path(path.value) + ")")
    end

    def javascript_path(path)
      Sass::Script::String.new(sprockets_context.javascript_path(path.value), :string)
    end

    def javascript_url(path)
      Sass::Script::String.new("url(" + sprockets_context.javascript_path(path.value) + ")")
    end

    def stylesheet_path(path)
      Sass::Script::String.new(sprockets_context.stylesheet_path(path.value), :string)
    end

    def stylesheet_url(path)
      Sass::Script::String.new("url(" + sprockets_context.stylesheet_path(path.value) + ")")
    end

    def asset_data_url(path)
      Sass::Script::String.new("url(" + sprockets_context.asset_data_uri(path.value) + ")")
    end

    protected
      def sprockets_context
        options[:sprockets][:context]
      end

      def sprockets_environment
        options[:sprockets][:environment]
      end
  end
end
