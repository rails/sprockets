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
      # cache_store = SassCacheStore.new(context.environment)

      options = {
        :filename => context.pathname.to_s,
        :syntax => syntax,
        :cache => false,
        :read_cache => false,
        :importer => SassImporter.new(context.pathname.to_s),
        :load_paths => context.environment.paths.map { |path| SassImporter.new(path.to_s) },
        :sprockets => {
          :context => context,
          :environment => context.environment
        }
      }

      result = ::Sass::Engine.new(data, options).render

      # Track all imported files
      filenames = ([options[:importer].imported_filenames] + options[:load_paths].map(&:imported_filenames)).flatten.uniq
      filenames.each { |filename| context.depend_on(filename) }

      result
    rescue ::Sass::SyntaxError => e
      # Annotates exception message with parse line number
      context.__LINE__ = e.sass_backtrace.first[:line]
      raise e
    end
  end
end
