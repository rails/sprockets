require 'sprockets/encoding_utils'
require 'sprockets/http_utils'

module Sprockets
  module Mime
    include HTTPUtils

    # Public: Mapping of MIME type Strings to properties Hash.
    #
    # key   - MIME Type String
    # value - Hash
    #   extensions - Array of extnames
    #   charset    - Default Encoding or function to detect encoding
    #
    # Returns Hash.
    attr_reader :mime_types

    # Internal: Mapping of MIME extension Strings to MIME type Strings.
    #
    # Used for internal fast lookup purposes.
    #
    # Examples:
    #
    #   mime_exts['.js'] #=> 'application/javascript'
    #
    # key   - MIME extension String
    # value - MIME Type String
    #
    # Returns Hash.
    attr_reader :mime_exts

    # Public: Register a new mime type.
    #
    # mime_type - String MIME Type
    # options - Hash
    #   extensions: Array of String extnames
    #   charset: Proc/Method that detects the charset of a file.
    #            See EncodingUtils.
    #
    # Returns nothing.
    def register_mime_type(mime_type, options = {})
      # Legacy extension argument, will be removed from 4.x
      if options.is_a?(String)
        options = { extensions: [options] }
      end

      extnames = Array(options[:extensions]).map { |extname|
        Sprockets::Utils.normalize_extension(extname)
      }

      charset = options[:charset]
      charset ||= EncodingUtils::DETECT if mime_type.start_with?('text/')

      mutate_config(:mime_exts) do |mime_exts|
        extnames.each do |extname|
          mime_exts[extname] = mime_type
        end
        mime_exts
      end

      mutate_config(:mime_types) do |mime_types|
        type = { extensions: extnames }
        type[:charset] = charset if charset
        mime_types.merge(mime_type => type)
      end
    end

    # Internal: Get detecter function for MIME type.
    #
    # mime_type - String MIME type
    #
    # Returns Proc detector or nil if none is available.
    def mime_type_charset_detecter(mime_type)
      if type = mime_types[mime_type]
        if detect = type[:charset]
          return detect
        end
      end
    end

    # Public: Read file on disk with MIME type specific encoding.
    #
    # filename     - String path
    # content_type - String MIME type
    #
    # Returns String file contents transcoded to UTF-8 or in its external
    # encoding.
    def read_file(filename, content_type = nil)
      data = File.binread(filename)

      if detect = mime_type_charset_detecter(content_type)
        detect.call(data).encode(Encoding::UTF_8, :universal_newline => true)
      else
        data
      end
    end

    # Public: Mapping of supported HTTP Content/Transfer encodings
    #
    # key   - String name
    # value - Method/Proc to encode data
    #
    # Returns Hash.
    attr_reader :encodings

    # Public: Register a new encoding.
    #
    # Examples
    #
    #   register_encoding :gzip, EncodingUtils::GZIP
    #
    # key    - String name
    # encode - Method/Proc to encode data
    #
    # Returns nothing.
    def register_encoding(name, encode)
      mutate_config(:encodings) do |encodings|
        encodings.merge(name.to_s => encode)
      end
    end

    private
      # Internal: Get a postprocessor to perform the encoding.
      #
      # encoding - String encoding.
      #
      # Returns an Array of Processors.
      def unwrap_encoding_processors(encoding)
        processors = []
        if encoder = self.encodings[encoding]
          processors << lambda do |input|
            { data: encoder.call(input[:data]), encoding: encoding }
          end
        end
        processors
      end
  end
end
