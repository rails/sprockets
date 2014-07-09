require 'rack/utils'
require 'sass'
require 'set'

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
    def initialize(options = {}, &block)
      @cache_version = options[:cache_version]

      @functions = Module.new
      @functions.send(:include, Functions)
      @functions.send(:include, options[:functions]) if options[:functions]
      @functions.class_eval(&block) if block_given?
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = {
        filename: input[:filename],
        syntax: self.class.syntax,
        cache_store: CacheStore.new(input[:cache], @cache_version),
        load_paths: input[:environment].paths,
        sprockets: {
          context: context,
          environment: input[:environment],
          dependencies: context.metadata[:dependency_paths]
        }
      }

      engine = ::Sass::Engine.new(input[:data], options)
      raise unless ::Sass::Script::Functions.instance_methods.include?(:javascript_path)
      css = Utils.module_include(::Sass::Script::Functions, @functions) do
        engine.render
      end

      # Track all imported files
      engine.dependencies.map do |dependency|
        context.metadata[:dependency_paths] << dependency.options[:filename]
      end

      context.metadata.merge(data: css)
    end

    # Internal: Functions injected into Sass environment.
    #
    # Extending this module is not a public API.
    module Functions
      # Public
      def asset_path(path, options = {})
        # raise NotImplementedError
        ::Sass::Script::String.new(sprockets_context.asset_path(path.value, options), :string)
      end

      # Public
      def asset_url(path, options = {})
        ::Sass::Script::String.new("url(#{asset_path(path, options).value})")
      end

      # Public
      def image_path(path)
        asset_path(path, type: :image)
      end

      # Public
      def image_url(path)
        asset_url(path, type: :image)
      end

      # Public
      def video_path(path)
        asset_path(path, type: :video)
      end

      # Public
      def video_url(path)
        asset_url(path, type: :video)
      end

      # Public
      def audio_path(path)
        asset_path(path, type: :audio)
      end

      # Public
      def audio_url(path)
        asset_url(path, type: :audio)
      end

      # Public
      def font_path(path)
        asset_path(path, type: :font)
      end

      # Public
      def font_url(path)
        asset_url(path, type: :font)
      end

      # Public
      def javascript_path(path)
        asset_path(path, type: :javascript)
      end

      # Public
      def javascript_url(path)
        asset_url(path, type: :javascript)
      end

      # Public
      def stylesheet_path(path)
        asset_path(path, type: :stylesheet)
      end

      # Public
      def stylesheet_url(path)
        asset_url(path, type: :stylesheet)
      end

      # Public
      def asset_data_url(path)
        if asset = sprockets_environment.find_asset(path.value, accept_encoding: 'base64')
          sprockets_dependencies << asset.filename
          url = "data:#{asset.content_type};base64,#{Rack::Utils.escape(asset.to_s)}"
          ::Sass::Script::String.new("url(" + url + ")")
        end
      end

      protected
        # Internal
        def sprockets_context
          options[:sprockets][:context]
        end

        # Internal
        def sprockets_environment
          options[:sprockets][:environment]
        end

        # Internal
        def sprockets_dependencies
          options[:sprockets][:dependencies]
        end
    end

    # Internal: Cache wrapper for Sprockets cache adapter.
    class CacheStore < ::Sass::CacheStores::Base
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
  end

  class ScssTemplate < SassTemplate
    def self.syntax
      :scss
    end
  end

  # Deprecated: Use Sprockets::SassTemplate::Functions instead.
  SassFunctions = SassTemplate::Functions

  # Deprecated: Use Sprockets::SassTemplate::CacheStore instead.
  SassCacheStore = SassTemplate::CacheStore
end
