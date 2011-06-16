require 'tilt'

module Sprockets
  class Processor < Tilt::Template
    def self.processor
      @processor
    end

    def self.name
      "Sprockets::Processor (#{@name})"
    end

    def self.to_s
      name
    end

    def prepare
    end

    def evaluate(context, locals)
      self.class.processor.call(context, data)
    end
  end
end
