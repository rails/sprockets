require 'rack/mime'

module Sprockets
  module Mime
    # Returns a `Hash` of registered mime types registered on the
    # environment and those part of `Rack::Mime`.
    #
    # If an `ext` is given, it will lookup the mime type for that extension.
    def mime_types(ext = nil)
      if ext
        @mime_types[ext] || Rack::Mime::MIME_TYPES[ext]
      else
        Rack::Mime::MIME_TYPES.merge(@mime_types)
      end
    end

    # Returns a `Hash` of explicitly registered mime types.
    def registered_mime_types
      @mime_types.dup
    end

    # Register a new mime type.
    def register_mime_type(mime_type, ext)
      ext = Sprockets::Utils.normalize_extension(ext)
      @extensions.push(ext)
      @mime_types[ext] = mime_type
    end

    # Returns the correct encoding for a given mime type, while falling
    # back on the default external encoding, if it exists.
    def encoding_for_mime_type(type)
      encoding = Encoding::BINARY if type =~ %r{^(image|audio|video)/}
      encoding ||= Sprockets.default_external_encoding
      encoding
    end
  end
end
