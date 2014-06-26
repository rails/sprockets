require 'base64'
require 'stringio'
require 'zlib'

module Sprockets
  module EncodingUtils
    extend self

    ## Binary encodings ##

    # Public: Use deflate to compress enumerable data stream.
    #
    # enum - Enumerable of String data
    #
    # Returns a compressed String
    def deflate(enum)
      deflater = Zlib::Deflate.new(
        Zlib::BEST_COMPRESSION,
        -Zlib::MAX_WBITS,
        Zlib::MAX_MEM_LEVEL,
        Zlib::DEFAULT_STRATEGY
      )
      enum.each { |chunk| deflater << chunk }
      deflater.finish
    end

    # Public: Alias for CodingUtils.deflate
    DEFLATE = method(:deflate)

    # Public: Use gzip to compress enumerable data stream.
    #
    # enum - Enumerable of String data
    #
    # Returns a compressed String
    def gzip(enum)
      io = StringIO.new
      gz = Zlib::GzipWriter.new(io, Zlib::BEST_COMPRESSION)
      enum.each { |chunk| gz << chunk }
      gz.finish
      io.string
    end

    # Public: Alias for CodingUtils.gzip
    GZIP = method(:gzip)

    # Public: Use base64 to encode enumerable data stream.
    #
    # enum - Enumerable of String data
    #
    # Returns a encoded String
    def base64(enum)
      io = StringIO.new
      enum.each { |chunk| io << chunk }
      Base64.strict_encode64(io.string)
    end

    # Public: Alias for CodingUtils.base64
    BASE64 = method(:base64)


    ## Charset encodings ##

    # Internal: Mapping unicode encodings to byte order markers.
    BOM = {
      Encoding::UTF_32LE => [0xFF, 0xFE, 0x00, 0x00],
      Encoding::UTF_32BE => [0x00, 0x00, 0xFE, 0xFF],
      Encoding::UTF_8    => [0xEF, 0xBB, 0xBF],
      Encoding::UTF_16LE => [0xFF, 0xFE],
      Encoding::UTF_16BE => [0xFE, 0xFF]
    }

    # Public: Basic string detecter.
    #
    # Attempts to parse any Unicode BOM otherwise falls back to the
    # environment's external encoding.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns encoded String.
    def detect(str)
      str = detect_unicode_bom(str)

      # Attempt Charlock detection
      if str.encoding == Encoding::BINARY
        charlock_detect(str)
      end

      # Fallback to UTF-8
      if str.encoding == Encoding::BINARY
        str.force_encoding(Encoding.default_external)
      end

      str
    end

    # Public: Alias for EncodingUtils.detect_unicode
    DETECT = method(:detect)

    # Internal: Use Charlock Holmes to detect encoding.
    #
    # To enable this code path, require 'charlock_holmes'
    #
    # Returns encoded String.
    def charlock_detect(str)
      if defined? CharlockHolmes::EncodingDetector
        if detected = CharlockHolmes::EncodingDetector.detect(str)
          str.force_encoding(detected[:encoding]) if detected[:encoding]
        end
      end

      str
    end

    # Public: Detect Unicode string.
    #
    # Attempts to parse Unicode BOM and falls back to UTF-8.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns encoded String.
    def detect_unicode(str)
      str = detect_unicode_bom(str)

      # Fallback to UTF-8
      if str.encoding == Encoding::BINARY
        str.force_encoding(Encoding::UTF_8)
      end

      str
    end

    # Public: Alias for EncodingUtils.detect_unicode
    DETECT_UNICODE = method(:detect_unicode)

    # Public: Detect and strip BOM from possible unicode string.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns UTF 8/16/32 encoded String without BOM or the original String if
    # no BOM was present.
    def detect_unicode_bom(str)
      bom_bytes = str.byteslice(0, 4).bytes.to_a

      BOM.each do |encoding, bytes|
        if bom_bytes[0, bytes.size] == bytes
          str = str.dup
          str.force_encoding(Encoding::BINARY)
          str.slice!(0, bytes.size)
          str.force_encoding(encoding)
          return str
        end
      end

      return str
    end

    # Public: Detect and strip @charset from CSS style sheet.
    #
    # str - String.
    #
    # Returns a encoded String.
    def detect_css(str)
      str = detect_unicode_bom(str)

      if name = scan_css_charset(str)
        encoding = Encoding.find(name)
        str = str.dup
        str.force_encoding(encoding)
        len = "@charset \"#{name}\";".encode(encoding).size
        str.slice!(0, len)
        str
      end

      # Fallback to UTF-8
      if str.encoding == Encoding::BINARY
        str.force_encoding(Encoding::UTF_8)
      end

      str
    end

    # Public: Alias for EncodingUtils.detect_css
    DETECT_CSS = method(:detect_css)

    # Internal: @charset bytes
    CHARSET_START = [0x40, 0x63, 0x68, 0x61, 0x72, 0x73, 0x65, 0x74, 0x20, 0x22]

    # Internal: Scan binary CSS string for @charset encoding name.
    #
    # str - ASCII-8BIT encoded String
    #
    # Returns encoding String name or nil.
    def scan_css_charset(str)
      name = nil
      ascii_bytes = Enumerator.new do |y|
        str.each_byte do |byte|
          # Halt on line breaks
          break if byte == 0x0A || byte == 0x0D
          y << byte if 0x0 < byte && byte <= 0xFF
        end
      end

      buf = []
      loop do
        buf << ascii_bytes.next
        break if buf.size == CHARSET_START.size
      end

      if buf == CHARSET_START
        buf = []
        loop do
          byte = ascii_bytes.next

          if byte == 0x22 && ascii_bytes.peek == 0x3B
            name = buf.pack('C*')
            break
          else
            buf << byte
          end
        end
      end

      name
    end

    # Public: Detect charset from HTML document. Defaults to ISO-8859-1.
    #
    # str - String.
    #
    # Returns a encoded String.
    def detect_html(str)
      str = detect_unicode_bom(str)

      # Attempt Charlock detection
      if str.encoding == Encoding::BINARY
        charlock_detect(str)
      end

      # Fallback to ISO-8859-1
      if str.encoding == Encoding::BINARY
        str.force_encoding(Encoding::ISO_8859_1)
      end

      str
    end

    # Public: Alias for EncodingUtils.detect_html
    DETECT_HTML = method(:detect_html)
  end
end
