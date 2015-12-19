require 'json'

module Sprockets
  module SourceMapUtils
    extend self

    # Public: Concatenate two source maps.
    #
    # For an example, if two js scripts are concatenated, the individual source
    # maps for those files can be concatenated to map back to the originals.
    #
    # Examples
    #
    #     script3 = "#{script1}#{script2}"
    #     map3    = concat_source_maps(map1, map2)
    #
    # a - Array of source mapping Hashes
    # b - Array of source mapping Hashes
    #
    # Returns a new Array of source mapping Hashes.
    def concat_source_maps(a, b)
      a ||= []
      b ||= []
      mappings = a.dup

      if a.any?
        offset = a.last[:generated][0]
      else
        offset = 0
      end

      b.each do |m|
        mappings << m.merge(generated: [m[:generated][0] + offset, m[:generated][1]])
      end
      mappings
    end

    # Public: Combine two seperate source map transformations into a single
    # mapping.
    #
    # Source transformations may happen in discrete steps producing separate
    # source maps. These steps can be combined into a single mapping back to
    # the source.
    #
    # For an example, CoffeeScript may transform a file producing a map. Then
    # Uglifier processes the result and produces another map. The CoffeeScript
    # map can be combined with the Uglifier map so the source lines of the
    # minified output can be traced back to the original CoffeeScript file.
    #
    # a - Array of source mapping Hashes
    # b - Array of source mapping Hashes
    #
    # Returns a new Array of source mapping Hashes.
    def combine_source_maps(a, b)
      a ||= []
      return b.dup if a.empty?

      mappings = []

      b.each do |m|
        om = bsearch_mappings(a, m[:original])
        next unless om
        mappings << om.merge(generated: m[:generated])
      end

      mappings
    end

    # Public: Compare two source map offsets.
    #
    # Compatible with Array#sort.
    #
    # a - Array [line, column]
    # b - Array [line, column]
    #
    # Returns -1 if a < b, 0 if a == b and 1 if a > b.
    def compare_source_offsets(a, b)
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

    # Public: Search Array of mappings for closest offset.
    #
    # mappings - Array of mapping Hash objects
    # offset  - Array [line, column]
    #
    # Returns mapping Hash object.
    def bsearch_mappings(mappings, offset, from = 0, to = mappings.size - 1)
      mid = (from + to) / 2

      if from > to
        return from < 1 ? nil : mappings[from-1]
      end

      case compare_source_offsets(offset, mappings[mid][:generated])
      when 0
        mappings[mid]
      when -1
        bsearch_mappings(mappings, offset, from, mid - 1)
      when 1
        bsearch_mappings(mappings, offset, mid + 1, to)
      end
    end

    # Public: Decode Source Map JSON into Ruby objects.
    #
    # json - String source map JSON
    #
    # Returns Hash.
    def decode_json_source_map(json)
      map = JSON.parse(json)
      map['mappings'] = decode_vlq_mappings(map['mappings'], sources: map['sources'], names: map['names'])
      map
    end

    # Public: Encode mappings to Source Map JSON.
    #
    # mappings - Array of Hash or String VLQ encoded mappings
    # sources  - Array of String sources
    # names    - Array of String names
    # filename - String filename
    #
    # Returns JSON String.
    def encode_json_source_map(mappings, sources: nil, names: nil, filename: nil)
      case mappings
      when String
      when Array
        sources ||= mappings.map { |m| m[:source] }.uniq.compact
        names   ||= mappings.map { |m| m[:name] }.uniq.compact
        mappings = encode_vlq_mappings(mappings, sources: sources, names: names)
      else
        raise TypeError, "could not encode mappings: #{mappings}"
      end

      JSON.generate({
        "version"   => 3,
        "file"      => filename,
        "mappings"  => mappings,
        "sources"   => sources,
        "names"     => names
      })
    end

    # Public: Decode VLQ mappings and match up sources and symbol names.
    #
    # str     - VLQ string from 'mappings' attribute
    # sources - Array of Strings from 'sources' attribute
    # names   - Array of Strings from 'names' attribute
    #
    # Returns an Array of Mappings.
    def decode_vlq_mappings(str, sources: [], names: [])
      mappings = []

      source_id       = 0
      original_line   = 1
      original_column = 0
      name_id         = 0

      vlq_decode_mappings(str).each_with_index do |group, index|
        generated_column = 0
        generated_line   = index + 1

        group.each do |segment|
          generated_column += segment[0]
          generated = [generated_line, generated_column]

          if segment.size >= 4
            source_id        += segment[1]
            original_line    += segment[2]
            original_column  += segment[3]

            source   = sources[source_id]
            original = [original_line, original_column]
          else
            # TODO: Research this case
            next
          end

          if segment[4]
            name_id += segment[4]
            name     = names[name_id]
          end

          mapping = {source: source, generated: generated, original: original}
          mapping[:name] = name if name
          mappings << mapping
        end
      end

      mappings
    end

    # Public: Encode mappings Hash into a VLQ encoded String.
    #
    # mappings - Array of Hash mapping objects
    # sources  - Array of String sources (default: mappings source order)
    # names    - Array of String names (default: mappings name order)
    #
    # Returns a VLQ encoded String.
    def encode_vlq_mappings(mappings, sources: nil, names: nil)
      sources ||= mappings.map { |m| m[:source] }.uniq.compact
      names   ||= mappings.map { |m| m[:name] }.uniq.compact

      sources_index = Hash[sources.each_with_index.to_a]
      names_index   = Hash[names.each_with_index.to_a]

      source_id     = 0
      source_line   = 1
      source_column = 0
      name_id       = 0

      by_lines = mappings.group_by { |m| m[:generated][0] }

      ary = (1..(by_lines.keys.max || 1)).map do |line|
        generated_column = 0

        (by_lines[line] || []).map do |mapping|
          group = []
          group << mapping[:generated][1] - generated_column
          group << sources_index[mapping[:source]] - source_id
          group << mapping[:original][0] - source_line
          group << mapping[:original][1] - source_column
          group << names_index[mapping[:name]] - name_id if mapping[:name]

          generated_column = mapping[:generated][1]
          source_id        = sources_index[mapping[:source]]
          source_line      = mapping[:original][0]
          source_column    = mapping[:original][1]
          name_id          = names_index[mapping[:name]] if mapping[:name]

          group
        end
      end

      vlq_encode_mappings(ary)
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
