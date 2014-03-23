require 'yui/compressor'

module Sprockets
  class YUICompressor
    def self.call(input)
      data = input[:data]

      case input[:content_type]
      when 'application/javascript'
        ::YUI::JavaScriptCompressor.new.compress(data)
      when 'text/css'
        ::YUI::CssCompressor.new.compress(data)
      else
        data
      end
    end
  end
end
