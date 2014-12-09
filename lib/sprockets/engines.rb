require 'sprockets/lazy_processor'
require 'sprockets/legacy_tilt_processor'
require 'sprockets/utils'

module Sprockets
  # `Engines` provides a global and `Environment` instance registry.
  #
  # An engine is a type of processor that is bound to a filename
  # extension. `application.js.coffee` indicates that the
  # `CoffeeScriptProcessor` engine will be ran on the file.
  #
  # Extensions can be stacked and will be evaulated from right to
  # left. `application.js.coffee.erb` will first run `ERBProcessor`
  # then `CoffeeScriptProcessor`.
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
  #     Sprockets.register_engine '.sass', SassProcessor
  #
  module Engines
    # Returns a `Hash` of `Engine`s registered on the `Environment`.
    # If an `ext` argument is supplied, the `Engine` associated with
    # that extension will be returned.
    #
    #     environment.engines
    #     # => {".coffee" => CoffeeScriptProcessor, ".sass" => SassProcessor, ...}
    #
    attr_reader :engines

    # Internal: Returns a `Hash` of engine extensions to mime types.
    #
    # # => { '.coffee' => 'application/javascript' }
    attr_reader :engine_mime_types

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
    #     environment.register_engine '.coffee', CoffeeScriptProcessor
    #
    def register_engine(ext, klass, options = {})
      ext = Sprockets::Utils.normalize_extension(ext)

      if klass.class == Sprockets::LazyProcessor || klass.respond_to?(:call)
        mutate_config(:engines) do |engines|
          engines.merge(ext => klass)
        end
        if options[:mime_type]
          mutate_config(:engine_mime_types) do |mime_types|
            mime_types.merge(ext.to_s => options[:mime_type])
          end
        end
      else
        mutate_config(:engines) do |engines|
          engines.merge(ext => LegacyTiltProcessor.new(klass))
        end
        if klass.respond_to?(:default_mime_type) && klass.default_mime_type
          mutate_config(:engine_mime_types) do |mime_types|
            mime_types.merge(ext.to_s => klass.default_mime_type)
          end
        end
      end
    end
  end
end
