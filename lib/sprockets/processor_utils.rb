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

    # Public: Compose processors in right to left order.
    #
    # processors - Array of processors callables
    #
    # Returns a composed Proc.
    def compose_processors(*processors)
      context = self

      if processors.length == 1
        obj = method(:call_processor).to_proc.curry[processors.first]
      else
        obj = method(:call_processors).to_proc.curry[processors]
      end

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
      metadata = (input[:metadata] || {}).dup

      processors.reverse_each do |processor|
        result = call_processor(processor, input.merge(data: data, metadata: metadata))
        data = result.delete(:data)
        metadata.merge!(result)
      end

      metadata.merge(data: data)
    end

    # Public: Invoke processor.
    #
    # processor - Processor callables
    # input - Hash of input data to pass to processor
    #
    # Returns a Hash with :data and other processor metadata key/values.
    def call_processor(processor, input)
      metadata = (input[:metadata] || {}).dup
      metadata[:data] = input[:data]

      case result = processor.call({data: "", metadata: {}}.merge(input))
      when NilClass
        metadata
      when Hash
        metadata.merge(result)
      when String
        metadata.merge(data: result)
      else
        raise TypeError, "invalid processor return type: #{result.class}"
      end
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
