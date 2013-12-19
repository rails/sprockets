module Sprockets
  class ClosureCompressor < Template
    self.default_mime_type = 'application/javascript'

    def render(context)
      require 'closure-compiler' unless defined? ::Closure::Compiler
      Closure::Compiler.new.compile(data)
    end
  end
end
