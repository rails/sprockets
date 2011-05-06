require 'tilt'

module Sprockets
  class Compressor < Tilt::Template
    def prepare
    end

    def evaluate(context, locals, &block)
      environment = context.environment

      case context.content_type
      when 'application/javascript'
        if environment.js_compressor
          return environment.js_compressor.compress(data)
        end
      when 'text/css'
        if environment.css_compressor
          return environment.css_compressor.compress(data)
        end
      end

      data
    end
  end
end
