module Sprockets
  # `Processor` creates an anonymous processor class from a block.
  #
  #     register_preprocessor 'text/css', :my_processor do |context, data|
  #       # ...
  #     end
  #
  class Processor
    def self.make_processor(klass, proc = nil) # :nodoc:
      if !proc
        if klass.respond_to?(:call)
          proc = klass.method(:call)
        else
          return klass
        end
      end

      name = klass.to_s
      Class.new(Processor) do
        @name      = name
        @processor = proc
      end
    end

    # `processor` is a lambda or block
    def self.processor
      @processor
    end

    def self.name
      "Sprockets::Processor (#{@name})"
    end

    def self.to_s
      name
    end

    attr_reader :data

    def initialize(file, &block)
      @data = block.call
    end

    def render(context)
      # Legacy argument style.
      # Call processor block with `context` and `data`.
      if self.class.processor.respond_to?(:arity) && self.class.processor.arity == 2
        self.class.processor.call(context, data)
      else
        input = {
          environment: context.environment,
          context: context,
          logical_path: context.logical_path,
          content_type: context.content_type,
          data: data
        }
        self.class.processor.call(input)
      end
    end
  end
end
