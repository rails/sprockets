module Sprockets
  # Also see `SassImporter` for more infomation.
  class SassTemplate
    def self.syntax
      :sass
    end

    def self.call(input)
      require 'sass' unless defined? ::Sass

      unless ::Sass::Script::Functions < Sprockets::SassFunctions
        # Install custom functions. It'd be great if this didn't need to
        # be installed globally, but could be passed into Engine as an
        # option.
        ::Sass::Script::Functions.send :include, Sprockets::SassFunctions
      end

      options = {
        :filename => input[:filename],
        :syntax => syntax,
        :cache_store => SassCacheStore.new(input[:environment]),
        :importer => SassImporter.new(input[:filename]),
        :load_paths => input[:environment].paths.map { |path| SassImporter.new(path.to_s) },
        :sprockets => {
          :context => input[:context],
          :environment => input[:environment]
        }
      }

      result = ::Sass::Engine.new(input[:data], options).render

      # Track all imported files
      filenames = ([options[:importer].imported_filenames] + options[:load_paths].map(&:imported_filenames)).flatten.uniq
      filenames.each { |filename| input[:context].depend_on(filename) }

      result
    rescue ::Sass::SyntaxError => e
      # Annotates exception message with parse line number
      context.__LINE__ = e.sass_backtrace.first[:line]
      raise e
    end
  end

  class ScssTemplate < SassTemplate
    def self.syntax
      :scss
    end
  end
end
