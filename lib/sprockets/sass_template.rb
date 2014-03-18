module Sprockets
  # Also see `SassImporter` for more infomation.
  class SassTemplate < Template
    def self.default_mime_type
      'text/css'
    end

    def syntax
      :sass
    end

    def render(context)
      require 'sass' unless defined? ::Sass

      unless ::Sass::Script::Functions < Sprockets::SassFunctions
        # Install custom functions. It'd be great if this didn't need to
        # be installed globally, but could be passed into Engine as an
        # option.
        ::Sass::Script::Functions.send :include, Sprockets::SassFunctions
      end

      # Use custom importer that knows about Sprockets Caching
      cache_store = SassCacheStore.new(context.environment)

      options = {
        :filename => context.pathname.to_s,
        :syntax => syntax,
        :cache_store => cache_store,
        :load_paths => context.environment.paths,
        :sprockets => {
          :context => context,
          :environment => context.environment
        }
      }

      engine = ::Sass::Engine.new(data, options)
      css = engine.render

      # Track all imported files
      engine.dependencies.each do |dependency|
        context.depend_on(dependency.options[:filename])
      end

      css
    rescue ::Sass::SyntaxError => e
      # Annotates exception message with parse line number
      context.__LINE__ = e.sass_backtrace.first[:line]
      raise e
    end
  end
end
