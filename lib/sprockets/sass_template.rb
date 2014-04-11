require 'sass'

module Sprockets
  # Also see `SassImporter` for more infomation.
  class SassTemplate
    def self.syntax
      :sass
    end

    def self.call(*args)
      new.call(*args)
    end

    def initialize
      unless ::Sass::Script::Functions < Sprockets::SassFunctions
        # Install custom functions. It'd be great if this didn't need to
        # be installed globally, but could be passed into Engine as an
        # option.
        ::Sass::Script::Functions.send :include, Sprockets::SassFunctions
      end
    end

    def call(input)
      context = input[:environment].context_class.new(input)

      options = {
        filename: input[:filename],
        syntax: self.class.syntax,
        cache_store: SassCacheStore.new(input[:cache]),
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

    def initialize(cache)
      @cache = cache
    end

    def _store(key, version, sha, contents)
      @cache._set("#{VERSION}/#{version}/#{key}/#{sha}", contents)
    end

    def _retrieve(key, version, sha)
      @cache._get("#{VERSION}/#{version}/#{key}/#{sha}")
    end

    def path_to(key)
      key
    end
  end
end
