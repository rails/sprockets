require 'closure-compiler'

module Sprockets
  class ClosureCompressor
    def self.call(*args)
      new.call(*args)
    end

    def initialize(*args)
      @compiler = Closure::Compiler.new(*args)
    end

    def call(input)
      @compiler.compile(input[:data])
    end
  end
end
