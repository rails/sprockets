# frozen_string_literal: true
require 'rack/utils'
require 'sprockets/autoload'
require 'sprockets/source_map_utils'
require 'uri'

module Sprockets
  # Processor engine class for the SASS/SCSS compiler. Depends on the `sass` gem.
  #
  # For more information see:
  #
  #   https://github.com/sass/sass
  #   https://github.com/rails/sass-rails
  #
  class SassProcessor
    VERSION = '2'

    # Internal: Defines default sass syntax to use. Exposed so the ScssProcessor
    # may override it.
    def self.syntax
      :indented
    end

    # Public: Convert ::Sass::Script::Functions to dart-sass functions option.
    #
    # Returns Hash object.
    def self.functions(options = {})
      functions = {}
      instance = Class.new.extend(::Sass::Script::Functions)
      instance.define_singleton_method(:options, ->() { options })
      ::Sass::Script::Functions.public_instance_methods.each do |symbol|
        parameters = instance.method(symbol).parameters
          .filter { |parameter| parameter.first == :req }
          .map { |parameter| "$#{parameter.last}" }
        functions["#{symbol}(#{parameters.join(', ')})"] = lambda do |args|
          instance.send(symbol, *args)
        end
      end
      functions
    end

    # Public: Return singleton instance with default options.
    #
    # Returns SassProcessor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    # Public: Initialize template with custom options.
    #
    # options - Hash
    # cache_version - String custom cache version. Used to force a cache
    #                 change after code changes are made to Sass Functions.
    #
    def initialize(options = {}, &block)
      @cache_version = options[:cache_version]
      @cache_key = "#{self.class.name}:#{VERSION}:#{Autoload::Sass::Embedded::VERSION}:#{@cache_version}".freeze
      @sass_config = options[:sass_config] || {}
      @functions = Module.new do
        include Functions
        include options[:functions] if options[:functions]
        class_eval(&block) if block_given?
      end
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      result = Utils.module_include(::Sass::Script::Functions, @functions) do
        options = merge_options({
          functions: self.class.functions({
            sprockets: {
              context: context,
              environment: input[:environment],
              dependencies: context.metadata[:dependencies]
            }
          }),
          syntax: self.class.syntax,
          source_map: true,
          load_paths: context.environment.paths,
          url: URIUtils.build_asset_uri(input[:filename])
        })

        Autoload::Sass.compile_string(input[:data], **options)
      end

      css = result.css

      map = SourceMapUtils.format_source_map(JSON.parse(result.source_map), input)
      map = SourceMapUtils.combine_source_maps(input[:metadata][:map], map)

      # Track all imported files
      sass_dependencies = Set.new
      result.loaded_urls.each do |url|
        scheme, _host, path, _query = URIUtils.split_file_uri url
        if scheme == 'file'
          sass_dependencies << path
          context.metadata[:dependencies] << URIUtils.build_file_digest_uri(path)
        end
      end

      context.metadata.merge(data: css, sass_dependencies: sass_dependencies, map: map)
    end

    private

    def merge_options(options)
      defaults = @sass_config.dup

      if load_paths = defaults.delete(:load_paths)
        options[:load_paths] += load_paths
      end

      options.merge!(defaults)
      options
    end

    # Public: Functions injected into Sass context during Sprockets evaluation.
    #
    # This module may be extended to add global functionality to all Sprockets
    # Sass environments. Though, scoping your functions to just your environment
    # is preferred.
    #
    # module Sprockets::SassProcessor::Functions
    #   def asset_path(path, options = {})
    #   end
    # end
    #
    module Functions
      # Public: Generate a url for asset path.
      #
      # Default implementation is deprecated. Currently defaults to
      # Context#asset_path.
      #
      # Will raise NotImplementedError in the future. Users should provide their
      # own base implementation.
      #
      # Returns a Sass::Script::String.
      def asset_path(path, options = {})
        path = path.text

        path, _, query, fragment = URI.split(path)[5..8]
        path     = sprockets_context.asset_path(path, options)
        query    = "?#{query}" if query
        fragment = "##{fragment}" if fragment

        Autoload::Sass::Value::String.new("#{path}#{query}#{fragment}", quoted: true)
      end

      # Public: Generate a asset url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def asset_url(path, options = {})
        Autoload::Sass::Value::String.new("url(#{asset_path(path, options).text})", quoted: false)
      end

      # Public: Generate url for image path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def image_path(path)
        asset_path(path, type: :image)
      end

      # Public: Generate a image url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def image_url(path)
        asset_url(path, type: :image)
      end

      # Public: Generate url for video path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def video_path(path)
        asset_path(path, type: :video)
      end

      # Public: Generate a video url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def video_url(path)
        asset_url(path, type: :video)
      end

      # Public: Generate url for audio path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def audio_path(path)
        asset_path(path, type: :audio)
      end

      # Public: Generate a audio url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def audio_url(path)
        asset_url(path, type: :audio)
      end

      # Public: Generate url for font path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def font_path(path)
        asset_path(path, type: :font)
      end

      # Public: Generate a font url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def font_url(path)
        asset_url(path, type: :font)
      end

      # Public: Generate url for javascript path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def javascript_path(path)
        asset_path(path, type: :javascript)
      end

      # Public: Generate a javascript url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def javascript_url(path)
        asset_url(path, type: :javascript)
      end

      # Public: Generate url for stylesheet path.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def stylesheet_path(path)
        asset_path(path, type: :stylesheet)
      end

      # Public: Generate a stylesheet url() link.
      #
      # path - Sass::Script::String URL path
      #
      # Returns a Sass::Script::String.
      def stylesheet_url(path)
        asset_url(path, type: :stylesheet)
      end

      # Public: Generate a data URI for asset path.
      #
      # path - Sass::Script::String logical asset path
      #
      # Returns a Sass::Script::String.
      def asset_data_url(path)
        url = sprockets_context.asset_data_uri(path.text)
        Autoload::Sass::Value::String.new("url(" + url + ")", quoted: false)
      end

      protected
        # Public: The Environment.
        #
        # Returns Sprockets::Environment.
        def sprockets_environment
          options[:sprockets][:environment]
        end

        # Public: Mutatable set of dependencies.
        #
        # Returns a Set.
        def sprockets_dependencies
          options[:sprockets][:dependencies]
        end

        # Deprecated: Get the Context instance. Use APIs on
        # sprockets_environment or sprockets_dependencies directly.
        #
        # Returns a Context instance.
        def sprockets_context
          options[:sprockets][:context]
        end

    end
  end

  class ScssProcessor < SassProcessor
    def self.syntax
      :scss
    end
  end

  module ::Sass
    module Script
      module Functions
      end
    end
  end
end
