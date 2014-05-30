module Sprockets
  module Mime
    # Returns a `Hash` of mime types registered on the environment and those
    # part of `Rack::Mime`.
    attr_reader :mime_types

    # Register a new mime type.
    def register_mime_type(mime_type, options = {})
      # Legacy extension argument, will be removed from 4.x
      if options.is_a?(String)
        options = { extensions: [options] }
      end

      extnames = Array(options[:extensions]).map { |extname|
        Sprockets::Utils.normalize_extension(extname)
      }

      type = options[:type] || :binary
      unless type == :binary || type == :text
        raise ArgumentError, "type must be :binary or :text"
      end

      extnames.each do |extname|
        @mime_types[extname] = mime_type
      end
    end

    # Returns the correct encoding for a given mime type, while falling
    # back on the default external encoding, if it exists.
    def encoding_for_mime_type(type)
      encoding = ::Encoding::BINARY if type =~ %r{^(image|audio|video)/}
      encoding ||= Sprockets.default_external_encoding
      encoding
    end

    def matches_content_type?(mime_type, path)
      # TODO: Disallow nil mime type
      mime_type.nil? ||
        mime_type == "*/*" ||
        # TODO: Review performance
        mime_type == mime_types[parse_path_extnames(path)[1]]
    end
  end
end
