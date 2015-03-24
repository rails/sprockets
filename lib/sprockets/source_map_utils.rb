module Sprockets
  module SourceMapUtils
    extend self

    # Public: Compare two source map offsets.
    #
    # Compatible with Array#sort.
    #
    # a - Array [line, column]
    # b - Array [line, column]
    #
    # Returns -1 if a < b, 0 if a == b and 1 if a > b.
    def compare_offsets(a, b)
      diff = a[0] - b[0]
      diff = a[1] - b[1] if diff == 0

      if diff < 0
        -1
      elsif diff > 0
        1
      else
        0
      end
    end

    # Public: Base64 VLQ encoding
    #
    # Adopted from ConradIrwin/ruby-source_map
    #   https://github.com/ConradIrwin/ruby-source_map/blob/master/lib/source_map/vlq.rb
    #
    # Resources
    #
    #   http://en.wikipedia.org/wiki/Variable-length_quantity
    #   https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
    #   https://github.com/mozilla/source-map/blob/master/lib/source-map/base64-vlq.js
    #
    VLQ_BASE_SHIFT = 5
    VLQ_BASE = 1 << VLQ_BASE_SHIFT
    VLQ_BASE_MASK = VLQ_BASE - 1
    VLQ_CONTINUATION_BIT = VLQ_BASE

    BASE64_DIGITS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('')
    BASE64_VALUES = (0...64).inject({}) { |h, i| h[BASE64_DIGITS[i]] = i; h }

    # Public: Encode a list of numbers into a compact VLQ string.
    #
    # ary - An Array of Integers
    #
    # Returns a VLQ String.
    def vlq_encode(ary)
      result = []
      ary.each do |n|
        vlq = n < 0 ? ((-n) << 1) + 1 : n << 1
        loop do
          digit  = vlq & VLQ_BASE_MASK
          vlq  >>= VLQ_BASE_SHIFT
          digit |= VLQ_CONTINUATION_BIT if vlq > 0
          result << BASE64_DIGITS[digit]

          break unless vlq > 0
        end
      end
      result.join
    end

    # Public: Decode a VLQ string.
    #
    # str - VLQ encoded String
    #
    # Returns an Array of Integers.
    def vlq_decode(str)
      result = []
      chars = str.split('')
      while chars.any?
        vlq = 0
        shift = 0
        continuation = true
        while continuation
          char = chars.shift
          raise ArgumentError unless char
          digit = BASE64_VALUES[char]
          continuation = false if (digit & VLQ_CONTINUATION_BIT) == 0
          digit &= VLQ_BASE_MASK
          vlq   += digit << shift
          shift += VLQ_BASE_SHIFT
        end
        result << (vlq & 1 == 1 ? -(vlq >> 1) : vlq >> 1)
      end
      result
    end

    # Public: Encode a mapping array into a compact VLQ string.
    #
    # ary - Two dimensional Array of Integers.
    #
    # Returns a VLQ encoded String seperated by , and ;.
    def vlq_encode_mappings(ary)
      ary.map { |group|
        group.map { |segment|
          vlq_encode(segment)
        }.join(',')
      }.join(';')
    end

    # Public: Decode a VLQ string into mapping numbers.
    #
    # str - VLQ encoded String
    #
    # Returns an two dimensional Array of Integers.
    def vlq_decode_mappings(str)
      mappings = []

      str.split(';').each_with_index do |group, index|
        mappings[index] = []
        group.split(',').each do |segment|
          mappings[index] << vlq_decode(segment)
        end
      end

      mappings
    end
  end
end
