require "digest/md5"
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
      @digest  = Digest::MD5.hexdigest(contents)
    end

    def content_type
      pathname.content_type
    end

    def stale?
      if pathname.fingerprint
        false
      else
        mtime < File.mtime(to_path)
      end
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

    protected
      def read
        File.read(to_path)
      end
  end
end
