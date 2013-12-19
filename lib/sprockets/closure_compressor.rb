module Sprockets
  class ClosureCompressor < Template
    self.default_mime_type = 'application/javascript'

    def self.engine_initialized?
      defined?(::Closure::Compiler)
    end

    def initialize_engine
      require 'closure-compiler'
    end

    def evaluate(context, locals, &block)
      Closure::Compiler.new.compile(data)
    end
  end
end
