require 'base64'
require 'stringio'
require 'zlib'

module Sprockets
  module CodingUtils
    extend self

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
  end
end
