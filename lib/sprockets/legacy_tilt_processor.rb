module Sprockets
  # Deprecated: Wraps legacy engine and process Tilt templates with new
  # processor call signature.
  #
  # Will be removed in Sprockets 4.x.
  #
  #     LegacyTiltProcessor.new(Tilt::CoffeeScriptTemplate)
  #
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
