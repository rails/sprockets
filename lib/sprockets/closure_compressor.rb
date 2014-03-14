module Sprockets
  class ClosureCompressor < Template
    def render(context)
      require 'closure-compiler' unless defined? ::Closure::Compiler
      Closure::Compiler.new.compile(data)
    end
  end
end
