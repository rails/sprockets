module Sprockets
  class LegacyTiltProcessor
    def initialize(klass)
      @klass = klass
    end

    def name
      @klass.name
    end

    def to_s
      @klass.to_s
    end

    def call(input)
      filename = input[:filename]
      data     = input[:data]
      context  = input[:context]

      @klass.new(filename) { data }.render(context)
    end
  end
end
