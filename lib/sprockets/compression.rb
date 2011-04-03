module Sprockets
  module Compression
    attr_reader :css_compressor, :js_compressor

    def css_compressor=(compressor)
      expire_cache
      @css_compressor = compressor
    end

    def js_compressor=(compressor)
      expire_cache
      @js_compressor = compressor
    end

    def use_default_compressors
      begin
        require 'yui/compressor'
        self.css_compressor = YUI::CssCompressor.new
        self.js_compressor  = YUI::JavaScriptCompressor.new(:munge => true)
      rescue LoadError
      end

      begin
        require 'closure-compiler'
        self.js_compressor = Closure::Compiler.new
      rescue LoadError
      end

      nil
    end
  end
end
