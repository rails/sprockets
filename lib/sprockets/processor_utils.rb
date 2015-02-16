require 'sprockets/autoload_processor'

module Sprockets
  # Functional utilities for dealing with Processor functions.
  #
  # A Processor is a general function that my modify or transform an asset as
  # part of the pipeline. CoffeeScript to JavaScript conversion, Minification
  # or Concatenation are all implemented as seperate Processor steps.
  #
  # Processors maybe any object that responds to call. So procs or a class that
  # defines a self.call method.
  #
  # For ergonomics, processors may return a number of shorthand values.
  # Unfortunately, this means that processors can not compose via ordinary
  # function composition. The composition helpers here can help.
  module ProcessorUtils
    extend self

    # Internal: Setup autoload and wrapper for lazy loaded processor.
    #
    #   Sprockets.autoload_processor :CoffeeScriptProcessor, 'sprockets/coffee_script_processor'
    #
    # mod      - Symbol name of processor class/module
    # filename - String require path for module
    #
    # Returns AutoloadProcessor.
    def autoload_processor(mod, filename)
      autoload(mod, filename)
      if autoload?(mod)
        AutoloadProcessor.new(self, mod)
      else
        const_get(mod)
      end
    end

    # Public: Compose processors in right to left order.
    #
    # processors - Array of processors callables
    #
    # Returns a composed Proc.
    def compose_processors(*processors)
      context = self
      obj = method(:call_processors).to_proc.curry[processors]
      metaclass = (class << obj; self; end)
      metaclass.send(:define_method, :cache_key) do
        context.processors_cache_keys(processors)
      end
      obj
    end

    # Public: Invoke list of processors in right to left order.
    #
    # The right to left order processing mirrors standard function composition.
    # Think about:
    #
    #   bundle.call(uglify.call(coffee.call(input)))
    #
    # processors - Array of processor callables
    # input - Hash of input data to pass to each processor
    #
    # Returns a Hash with :data and other processor metadata key/values.
    def call_processors(processors, input)
      data = input[:data] || ""
      metadata = input[:metadata] || {}

      processors.reverse_each do |processor|
        result = processor.call(input.merge(data: data, metadata: metadata))
        case result
        when NilClass
        when Hash
          data = result.delete(:data) if result.key?(:data)
          metadata.merge!(result)
        when String
          data = result
        else
          raise TypeError, "invalid processor return type: #{result.class}"
        end
      end

      metadata.merge(data: data)
    end

    # Internal: Get processor defined cached key.
    #
    # processor - Processor function
    #
    # Returns JSON serializable key or nil.
    def processor_cache_key(processor)
      processor.cache_key if processor.respond_to?(:cache_key)
    end

    # Internal: Get combined cache keys for set of processors.
    #
    # processors - Array of processor functions
    #
    # Returns Array of JSON serializable keys.
    def processors_cache_keys(processors)
      processors.map { |processor| processor_cache_key(processor) }
    end
  end
end
