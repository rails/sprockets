module Sprockets
  class YUICompressor < Template
    def self.engine_initialized?
      defined?(::YUI)
    end

    def initialize_engine
      require 'yui/compressor'
    end

    def render(context)
      case context.content_type
      when 'application/javascript'
        YUI::JavaScriptCompressor.new.compress(data)
      when 'text/css'
        YUI::CssCompressor.new.compress(data)
      else
        data
      end
    end
  end
end
