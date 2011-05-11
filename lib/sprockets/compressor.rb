require 'tilt'

module Sprockets
  class Compressor < Tilt::Template
    def self.compressor
      @compressor
    end

    def self.name
      'Sprockets::Compressor'
    end

    def self.to_s
      "#{name} #{compressor.inspect}"
    end

    def prepare
    end

    def evaluate(context, locals, &block)
      self.class.compressor.compress(data)
    end
  end
end
