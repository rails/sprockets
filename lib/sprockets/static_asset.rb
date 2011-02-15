require "digest/sha1"
require "json"
require "rack/utils"
require "time"

module Sprockets
  class StaticAsset
    attr_reader :pathname, :mtime, :length, :digest

    def initialize(pathname)
      @pathname = Pathname.new(pathname)

      contents = read
      @mtime   = File.mtime(@pathname.path)
      @length  = Rack::Utils.bytesize(contents)
      @digest  = Digest::SHA1.hexdigest(contents)
    end

    def content_type
      pathname.content_type
    end

    def stale?
      mtime < File.mtime(to_path)
    end

    def each
      yield read
    end

    def to_path
      pathname.to_s
    end

    def to_s
      read
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    def self.json_create(obj)
      allocate.tap { |asset| asset.from_json(obj) }
    end

    def from_json(obj)
      @pathname = Pathname.new(obj['pathname'])
      @mtime    = Time.parse(obj['mtime'])
      @length   = obj['length']
      @digest   = obj['digest']
    end

    def to_json(*args)
      {
        :json_class => self.class.name,
        :pathname   => pathname.path,
        :mtime      => mtime,
        :length     => length,
        :digest     => digest
      }.to_json(*args)
    end

    protected
      def read
        File.read(to_path)
      end
  end
end
