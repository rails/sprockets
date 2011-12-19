require 'tilt'
require 'sprockets/sass_importer'

module Sprockets
  class SassTemplate < Tilt::Template
    self.default_mime_type = 'text/css'

    def self.engine_initialized?
      defined? ::Sass::Engine
    end

    def initialize_engine
      require_template_library 'sass'
    end

    def prepare
    end

    def syntax
      :sass
    end

    def evaluate(context, locals, &block)
      importer = SassImporter.new(context)

      options = {
        :filename => eval_file,
        :line => line,
        :syntax => syntax,
        :cache => false,
        :read_cache => false,
        :importer => importer,
        :load_paths => [importer]
      }

      ::Sass::Engine.new(data, options).render
    rescue ::Sass::SyntaxError => e
      context.__LINE__ = e.sass_backtrace.first[:line]
      raise e
    end
  end
end
