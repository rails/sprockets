require 'sprockets/eco_template'
require 'sprockets/ejs_template'
require 'sprockets/jst_processor'
require 'sprockets/mime'
require 'sprockets/utils'
require 'tilt'

module Sprockets
  # `Engines` provides a global and `Environment` instance registry.
  #
  # An engine is a type of processor that is bound to an filename
  # extension. `application.js.coffee` indicates that the
  # `CoffeeScriptTemplate` engine will be ran on the file.
  #
  # Extensions can be stacked and will be evaulated from right to
  # left. `application.js.coffee.erb` will first run `ERBTemplate`
  # then `CoffeeScriptTemplate`.
  #
  # All `Engine`s must follow the `Tilt::Template` interface. It is
  # recommended to subclass `Tilt::Template`.
  #
  # Its recommended that you register engine changes on your local
  # `Environment` instance.
  #
  #     environment.register_engine '.foo', FooProcessor
  #
  # The global registry is exposed for plugins to register themselves.
  #
  #     Sprockets.register_engine '.sass', SassTemplate
  #
  module Engines
    # Returns an `Array` of `Engine`s registered on the
    # `Environment`. If an `ext` argument is supplied, the `Engine`
    # register under that extension will be returned.
    #
    #     environment.engines
    #     # => [CoffeeScriptTemplate, SassTemplate, ...]
    #
    #     environment.engines('.coffee')
    #     # => CoffeeScriptTemplate
    #
    def engines(ext = nil)
      if ext
        ext = Sprockets::Utils.normalize_extension(ext)
        @engines[ext]
      else
        @engines.dup
      end
    end

    def engine_formats(ext = nil)
      if ext
        ext = Sprockets::Utils.normalize_extension(ext)
        @engine_formats[ext]
      else
        deep_copy_hash(@engine_formats)
      end
    end

    # Returns an `Array` of engine extension `String`s.
    #
    #     environment.engine_extensions
    #     # => ['.coffee', '.sass', ...]
    def engine_extensions
      @engines.keys
    end

    # Registers a new Engine `klass` for `ext`. If the `ext` already
    # has an engine registered, it will be overridden.
    #
    #     environment.register_engine '.coffee', CoffeeScriptTemplate
    #
    def register_engine(ext, klass)
      ext = Sprockets::Utils.normalize_extension(ext)
      @engines[ext] = klass

      if klass.respond_to?(:default_mime_type) && klass.default_mime_type
        if format_ext = extension_for_mime_type(klass.default_mime_type)
          @engine_formats[format_ext] << ext
        end
      end

      klass
    end

    private
      def deep_copy_hash(hash)
        initial = Hash.new { |h, k| h[k] = [] }
        hash.inject(initial) { |h, (k, a)| h[k] = a.dup; h }
      end
  end

  # Extend Sprockets module to provide global registry
  extend Engines
  @engines = {}
  @engine_formats = Hash.new { |h, k| h[k] = [] }

  # Cherry pick the default Tilt engines that make sense for
  # Sprockets. We don't need ones that only generate html like HAML.

  # Mmm, CoffeeScript
  register_engine '.coffee', Tilt::CoffeeScriptTemplate

  # JST engines
  register_engine '.jst',    JstProcessor
  register_engine '.eco',    EcoTemplate
  register_engine '.ejs',    EjsTemplate

  # CSS engines
  register_engine '.less',   Tilt::LessTemplate
  register_engine '.sass',   Tilt::SassTemplate
  register_engine '.scss',   Tilt::ScssTemplate

  # Other
  register_engine '.erb',    Tilt::ERBTemplate
  register_engine '.str',    Tilt::StringTemplate
end
