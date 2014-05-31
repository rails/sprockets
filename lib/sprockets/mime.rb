require 'sprockets/encoding_utils'

module Sprockets
  module Mime
    # Pubic: Mapping of MIME type Strings to properties Hash.
    #
    # key   - MIME Type String
    # value - Hash
    #   type       - :text or :binary
    #   extensions - Array of extnames
    #   decoder    - Proc to decode binary content
    #
    # Returns Hash.
    attr_reader :mime_types

    attr_reader :mime_exts

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

      decoder = options[:decoder]
      decoder ||= EncodingUtils.method(:decode) if type == :text

      extnames.each do |extname|
        @mime_exts[extname] = mime_type
      end

      @mime_types[mime_type] = {}
      @mime_types[mime_type][:type] = type
      @mime_types[mime_type][:extensions] = extnames
      @mime_types[mime_type][:decoder] = decoder if decoder
      @mime_types[mime_type]
    end

    def mime_type_for_extname(extname)
      @mime_exts[extname] # || 'application/octet-stream'
    end

    def matches_content_type?(mime_type, path)
      # TODO: Disallow nil mime type
      mime_type.nil? ||
        mime_type == "*/*" ||
        # TODO: Review performance
        mime_type == mime_type_for_extname(parse_path_extnames(path)[1])
    end
  end
end
