module Sprockets
  class ClosureCompressor
    def self.call(input)
      require 'closure-compiler' unless defined? ::Closure::Compiler
      data = input[:data]
      Closure::Compiler.new.compile(data)
    end
  end
end
