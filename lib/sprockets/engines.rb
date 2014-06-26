require 'sprockets/lazy_processor'
require 'sprockets/legacy_tilt_processor'
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
    attr_reader :engines

    # Internal: Returns a `Hash` of engine extensions to format extensions.
    #
    # # => { '.coffee' => '.js' }
    attr_reader :engine_extensions

    # Internal: Find and load engines by extension.
    #
    # extnames - Array of String extnames
    #
    # Returns Array of Procs.
    def unwrap_engines(extnames)
      extnames.map { |ext|
        engines[ext]
      }.map { |engine|
        unwrap_processor(engine)
      }
    end

    # Registers a new Engine `klass` for `ext`. If the `ext` already
    # has an engine registered, it will be overridden.
    #
    #     environment.register_engine '.coffee', CoffeeScriptTemplate
    #
    def register_engine(ext, klass, options = {})
      ext = Sprockets::Utils.normalize_extension(ext)

      @engines, @engine_extensions = @engines.dup, @engine_extensions.dup
      if klass.class == Sprockets::LazyProcessor || klass.respond_to?(:call)
        mutate_config(:engines) { |engines| engines[ext] = klass }
        if options[:mime_type]
          mutate_config(:engine_extensions) do |engine_extensions|
            engine_extensions[ext.to_s] = mime_types[options[:mime_type]][:extensions].first
          end
        end
      else
        mutate_config(:engines) { |engines| engines[ext] = LegacyTiltProcessor.new(klass) }
        if klass.respond_to?(:default_mime_type) && klass.default_mime_type
          mutate_config(:engine_extensions) do |engine_extensions|
            engine_extensions[ext.to_s] = mime_types[klass.default_mime_type][:extensions].first
          end
        end
      end
    end
  end
end
