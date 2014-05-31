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

    # Public: Decode and strip BOM from possible unicode string.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns UTF 8/16/32 encoded String without BOM or the original String if
    # no BOM was present.
    def decode_unicode_bom(str)
      BOM.each do |encoding, bytes|
        if str.bytes[0, bytes.size] == bytes
          str = str.dup
          str.slice!(0, bytes.size)
          str.force_encoding(encoding)
          return str
        end
      end

      return str
    end
  end
end
