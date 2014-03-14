require 'sprockets/eco_template'
require 'sprockets/ejs_template'
require 'sprockets/jst_processor'
require 'sprockets/utils'

module Sprockets
  # `Engines` provides a global and `Environment` instance registry.
  #
  # An engine is a type of processor that is bound to a filename
  # extension. `application.js.coffee` indicates that the
  # `CoffeeScriptTemplate` engine will be ran on the file.
  #
  # Extensions can be stacked and will be evaulated from right to
  # left. `application.js.coffee.erb` will first run `ERBTemplate`
  # then `CoffeeScriptTemplate`.
  #
  # All `Engine`s must follow the `Template` interface. It is
  # recommended to subclass `Template`.
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
    # Returns a `Hash` of `Engine`s registered on the `Environment`.
    # If an `ext` argument is supplied, the `Engine` associated with
    # that extension will be returned.
    #
    #     environment.engines
    #     # => {".coffee" => CoffeeScriptTemplate, ".sass" => SassTemplate, ...}
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

    # Returns an `Array` of engine extension `String`s.
    #
    #     environment.engine_extensions
    #     # => ['.coffee', '.sass', ...]
    def engine_extensions
      @engines.keys
    end

    # Returns an `Array` of engine extension to mime types.
    #
    # # => { '.coffee' => 'application/javascript' }
    def engine_mime_types
      @engine_mime_types.dup
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
        @engine_mime_types[ext.to_s] = klass.default_mime_type
      end
    end

    private
      def deep_copy_hash(hash)
        initial = Hash.new { |h, k| h[k] = [] }
        hash.each_with_object(initial) { |(k, a),h| h[k] = a.dup }
      end
  end
end
