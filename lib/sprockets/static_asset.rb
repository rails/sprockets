require "digest/md5"
require "rack/utils"

module Sprockets
  class StaticAsset
    attr_reader :pathname, :mtime, :length, :digest

    def initialize(pathname)
      @pathname = pathname

      contents = read
      @mtime   = File.mtime(pathname.path)
      @length  = Rack::Utils.bytesize(contents)
      @digest  = Digest::MD5.hexdigest(contents)
    end

    def content_type
      pathname.content_type
    end

    def stale?
      mtime < File.mtime(to_path)
    end

    def read
      File.read(to_path)
    end

    def each
      yield read
    end

    def to_path
      pathname.to_s
    end
  end
end
