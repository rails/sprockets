require 'erb'

module Sprockets
  class ERBProcessor
    # Public: Return singleton instance with default options.
    #
    # Returns ERBProcessor object.
    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def initialize(&block)
      @block = block
    end

    def call(input)
      if keyword_constructor? # Ruby 2.6+
        engine = ::ERB.new(input[:data], trim_mode: '<>')
      else
        engine = ::ERB.new(input[:data], nil, '<>')
      end

      context = input[:environment].context_class.new(input)
      klass = (class << context; self; end)
      klass.class_eval(&@block) if @block
      engine.def_method(klass, :_evaluate_template, input[:filename])
      data = context._evaluate_template
      context.metadata.merge(data: data)
    end

    private

    def keyword_constructor?
      return @keyword_constructor if defined? @keyword_constructor
      @keyword_constructor = ::ERB.instance_method(:initialize).parameters.include?([:key, :trim_mode])
    end
  end
end
