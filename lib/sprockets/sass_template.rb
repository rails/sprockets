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
      options = {
        :filename => input[:filename],
        :syntax => self.class.syntax,
        :cache_store => SassCacheStore.new(input[:cache]),
        :load_paths => input[:environment].paths,
        :sprockets => {
          :context => input[:context],
          :environment => input[:environment]
        }
      }

      engine = ::Sass::Engine.new(input[:data], options)
      css = engine.render

      # Track all imported files
      engine.dependencies.each do |dependency|
        input[:context].depend_on(dependency.options[:filename])
      end

      css
    rescue ::Sass::SyntaxError => e
      # Annotates exception message with parse line number
      input[:context].__LINE__ = e.sass_backtrace.first[:line]
      raise e
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
      @cache["#{VERSION}/#{version}/#{key}/#{sha}"] = contents
    end

    def _retrieve(key, version, sha)
      @cache["#{VERSION}/#{version}/#{key}/#{sha}"]
    end

    def path_to(key)
      key
    end
  end
end
