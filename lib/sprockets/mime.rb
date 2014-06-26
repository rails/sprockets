require 'sprockets/encoding_utils'

module Sprockets
  module Mime
    include HTTPUtils

    # Pubic: Mapping of MIME type Strings to properties Hash.
    #
    # key   - MIME Type String
    # value - Hash
    #   extensions - Array of extnames
    #   charset    - Default Encoding or function to detect encoding
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

    attr_reader :encodings

    def register_encoding(name, encode)
      mutate_config(:encodings) do |encodings|
        encodings.merge(name.to_s => encode)
      end
    end

    def unwrap_encoding_processors(accept_encodings)
      available_encodings = self.encodings.keys + ['identity']
      encoding = find_best_q_match(accept_encodings, available_encodings)

      processors = []
      if encoder = self.encodings[encoding]
        processors << lambda do |input|
          { data: encoder.call([input[:data]]), encoding: encoding }
        end
      end
      processors
    end
  end
end
