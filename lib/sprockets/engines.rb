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
    attr_reader :transformers

    def register_transformer(from, to, processor)
      mutate_hash_config(:transformers, from) do |transformers|
        transformers.merge(to => processor)
      end
    end

    # Internal: Find and load engines by extension.
    #
    # extnames - Array of String extnames
    #
    # Returns Array of Procs.
    def unwrap_engines(extnames)
      extnames.map { |ext|
        # TODO: Why just any extname works
        transformers[mime_exts[ext]].values.first
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

      from = mime_exts[ext]
      if from.nil?
        from = "sprockets/#{ext.sub(/^\./, '')}"
        register_mime_type(from, extensions: [ext])
      end

      to = klass.respond_to?(:default_mime_type) && klass.default_mime_type ?
        klass.default_mime_type : "*/*"
      register_transformer(from, to, LegacyTiltProcessor.new(klass))
    end
  end
end
