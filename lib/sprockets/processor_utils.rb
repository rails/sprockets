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
      method(:call_processors).to_proc.curry[processors]
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
  end
end
