module Sprockets
  module Encoding
    extend self

    # Internal: Mapping unicode encodings to byte order markers.
    BOM = {
      ::Encoding::UTF_32LE => [0xFF, 0xFE, 0x00, 0x00],
      ::Encoding::UTF_32BE => [0x00, 0x00, 0xFE, 0xFF],
      ::Encoding::UTF_8    => [0xEF, 0xBB, 0xBF],
      ::Encoding::UTF_16LE => [0xFF, 0xFE],
      ::Encoding::UTF_16BE => [0xFE, 0xFF]
    }

    # Public: Basic string decoder.
    #
    # Attempts to parse any Unicode BOM otherwise falls back to the
    # environment's external encoding.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns encoded String.
    def decode(str)
      str = decode_unicode_bom(str)

      # Fallback to UTF-8
      if str.encoding == ::Encoding::BINARY
        str.force_encoding(::Encoding.default_external)
      end

      str
    end

    # Public: Decode Unicode string.
    #
    # Attempts to parse Unicode BOM and falls back to UTF-8.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns encoded String.
    def decode_unicode(str)
      str = decode_unicode_bom(str)

      # Fallback to UTF-8
      if str.encoding == ::Encoding::BINARY
        str.force_encoding(::Encoding::UTF_8)
      end

      str
    end

    # Public: Decode and strip BOM from possible unicode string.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns UTF 8/16/32 encoded String without BOM or the original String if
    # no BOM was present.
    def decode_unicode_bom(str)
      str_bytes = str.bytes.to_a
      BOM.each do |encoding, bytes|
        if str_bytes[0, bytes.size] == bytes
          str = str.dup
          str.slice!(0, bytes.size)
          str.force_encoding(encoding)
          return str
        end
      end

      return str
    end

    CHARSET_START = [0x40, 0x63, 0x68, 0x61, 0x72, 0x73, 0x65, 0x74, 0x20, 0x22]

    # Public: Decode and strip @charset from CSS style sheet.
    #
    # str - String.
    #
    # Returns a encoded String.
    def decode_css_charset(str)
      str = decode_unicode_bom(str)

      state = :start
      i, len = 0, 0
      encoding_bytes = []

      str.each_byte do |byte|
        len += 1
        next if byte == 0x0

        case state
        when :start
          if byte == CHARSET_START[i]
            state = :charset
            i += 1
          else
            break
          end
        when :charset
          if byte == CHARSET_START[i]
            i += 1
            if i == CHARSET_START.size
              state = :encoding
            end
          else
            state = nil
          end
        when :encoding
          if byte == 0x22
            state = :quote
          else
            encoding_bytes << byte
          end
        when :quote
          if byte == 0x3B
            state = :success
            break
          end
        else
          break
        end
      end

      if state == :success
        name = encoding_bytes.pack('C*')
        encoding = ::Encoding.find(name)
        str = str.dup
        str.force_encoding(encoding)
        len = "@charset \"#{name}\";".encode(encoding).size
        str.slice!(0, len)
        str
      end

      # Fallback to UTF-8
      if str.encoding == ::Encoding::BINARY
        str.force_encoding(::Encoding::UTF_8)
      end

      str
    end
  end
end
