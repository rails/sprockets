module Sprockets
  # Internal: Used for lazy loading processors.
  #
  # Libraries should not use lazily loaded processors. They are only needed
  # internally by Sprockets since it has optionally dependencies such as
  # CoffeeScript that may not be available in the gem environment.
  class AutoloadProcessor
    # Initialize AutoloadProcessor wrapper
    #
    # See ProcessorUtils.autoload_processor for constructor method.
    #
    # mod  - Parent Module of processor class/module
    # name - Symbol name of processor class/module
    def initialize(mod, name)
      @mod  = mod
      @name = name.to_sym
    end

    # Full name of module.
    #
    # Returns String.
    def name
      "#{@mod}::#{@name}"
    end

    # Check if target constant is already loaded.
    #
    # Returns Boolean.
    def const_loaded?
      @mod.autoload?(@name)
    end

    # Delegate to processor#cache_key
    def cache_key
      load_processor.cache_key if load_processor.respond_to?(:cache_key)
    end

    # Delegate to processor#call
    def call(*args)
      load_processor.call(*args)
    end

    private
      def load_processor
        @processor ||= @mod.const_get(@name)
      end
  end
end
