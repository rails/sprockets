require 'sprockets/encoding_utils'

module Sprockets
  module Mime
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

    # Public: Test mime type against mime range.
    #
    #    match_mime_type?('text/html', 'text/*') => true
    #    match_mime_type?('text/plain', '*') => true
    #    match_mime_type?('text/html', 'application/json') => false
    #
    # Returns true if the given value is a mime match for the given mime match
    # specification, false otherwise.
    def match_mime_type?(value, matcher)
      v1, v2 = value.split('/', 2)
      m1, m2 = matcher.split('/', 2)
      (m1 == '*' || v1 == m1) && (m2.nil? || m2 == '*' || m2 == v2)
    end

    attr_reader :encodings

    def register_encoding(name, encode)
      mutate_config(:encodings) do |encodings|
        encodings.merge(name => encode)
      end
    end
  end
end
