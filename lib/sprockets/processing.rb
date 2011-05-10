module Sprockets
  module Processing
    def mime_types(ext = nil)
      if ext.nil?
        @mime_types.dup
      else
        ext = normalize_extension(ext)
        @mime_types[ext] || Rack::Mime::MIME_TYPES[ext]
      end
    end

    def filters(mime_type = nil)
      if mime_type
        @filters[mime_type].dup
      else
        @filters.inject({}) { |h, (k, a)| h[k] = a.dup; h }
      end
    end

    def css_compressor
      @css_compressor
    end

    def js_compressor
      @js_compressor
    end

    def register_mime_type(mime_type, ext)
      expire_index!
      @mime_types[normalize_extension(ext)] = mime_type
    end

    def register_filter(mime_type, klass)
      expire_index!
      @filters[mime_type].push(klass)
    end

    def unregister_filter(mime_type, klass)
      expire_index!
      @filters[mime_type].delete(klass)
    end

    def css_compressor=(compressor)
      expire_index!
      @css_compressor = compressor
    end

    def js_compressor=(compressor)
      expire_index!
      @js_compressor = compressor
    end

    private
      def normalize_extension(extension)
        extension = extension.to_s
        if extension[/^\./]
          extension
        else
          ".#{extension}"
        end
      end
  end
end
