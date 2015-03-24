require 'json'
require 'sprockets/source_map_utils'

module Sprockets
  class SourceMap
    include Enumerable
    include SourceMapUtils
    extend SourceMapUtils

    def self.from_json(json)
      from_hash JSON.parse(json)
    end

    def self.from_hash(hash)
      str     = hash['mappings']
      sources = hash['sources']
      names   = hash['names']

      new(decode_vlq_mappings(str, sources: sources, names: names), hash['file'])
    end

    def initialize(mappings = [], filename = nil)
      @mappings, @filename = mappings, filename
      @sources = @mappings.map { |m| m[:source] }.uniq.compact
      @names   = @mappings.map { |m| m[:name] }.uniq.compact
    end

    attr_reader :filename
    attr_reader :mappings
    attr_reader :sources, :names

    def [](i)
      @mappings[i]
    end

    def each(&block)
      @mappings.each(&block)
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.is_a?(self.class) &&
        self.mappings == other.mappings &&
        self.filename == other.filename
    end

    def +(other)
      mappings = @mappings.dup
      offset   = @mappings.any? ? @mappings.last[:generated][0]+1 : 0
      other.each do |m|
        mappings << m.merge(generated: [m[:generated][0] + offset, m[:generated][1]])
      end
      self.class.new(mappings, other.filename)
    end

    def |(other)
      return other.dup if self.mappings.empty?

      mappings = []

      other.each do |m|
        om = bsearch(m[:original])
        next unless om
        mappings << om.merge(generated: m[:generated])
      end

      self.class.new(mappings, other.filename)
    end

    def bsearch(offset, from = 0, to = self.mappings.size - 1)
      mid = (from + to) / 2

      # We haven't found a match
      if from > to
        return from < 1 ? nil : self[from-1]
      end

      # We found an exact match
      case compare_source_offsets(offset, self[mid][:generated])
      when 0
        self[mid]

      # We need to filter more
      when -1
        bsearch(offset, from, mid - 1)
      when 1
        bsearch(offset, mid + 1, to)
      end
    end

    def as_json(*)
      {
        "version"   => 3,
        "file"      => filename,
        "mappings"  => encode_vlq_mappings(self.mappings, sources: self.sources, names: self.names),
        "sources"   => self.sources,
        "names"     => self.names
      }
    end

    def to_json(*a)
      as_json.to_json(*a)
    end

    # Public: Get a pretty inspect output for debugging purposes.
    #
    # Returns a String.
    def inspect
      str = "#<#{self.class}"
      str << " filename=#{filename.inspect}" if filename
      mappings = self.mappings.map { |mapping|
        s = "#{mapping[:generated][0]}:#{mapping[:generated][1]}"
        s << "->#{mapping[:source]}@#{mapping[:original][0]}:#{mapping[:original][1]}"
        s << "##{mapping[:name]}" if mapping[:name]
        s
      }
      str << " mappings=#{mappings.inspect}" if mappings.any?
      str << ">"
      str
    end
  end
end
