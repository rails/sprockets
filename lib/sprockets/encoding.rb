module Sprockets
  module Encoding
    extend self

    BOM = {
      ::Encoding::UTF_32LE => [0xFF, 0xFE, 0x00, 0x00],
      ::Encoding::UTF_32BE => [0x00, 0x00, 0xFE, 0xFF],
      ::Encoding::UTF_8    => [0xEF, 0xBB, 0xBF],
      ::Encoding::UTF_16LE => [0xFF, 0xFE],
      ::Encoding::UTF_16BE => [0xFE, 0xFF]
    }

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
