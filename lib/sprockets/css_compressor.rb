require 'tilt'

module Sprockets
  class CssCompressor < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      environment = context.environment

      if environment.css_compressor
        environment.css_compressor.compress(data)
      else
        data
      end
    end
  end
end
