require 'tilt'

module Sprockets
  class JsCompressor < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      environment = context.environment

      if environment.js_compressor
        environment.js_compressor.compress(data)
      else
        data
      end
    end
  end
end
