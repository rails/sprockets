require "digest/md5"
require "rack/utils"

module Sprockets
  class StaticAsset
    attr_reader :pathname

    def initialize(environment, pathname)
      @pathname = pathname
    end

    def digest
      Digest::MD5.hexdigest(read)
    end

    def each
      yield read
    end

    def length
      Rack::Utils.bytesize(read)
    end

    def content_type
      pathname.content_type
    end

    def mtime
      File.mtime(pathname.path)
    end

    def stale?
      false
    end

    def read
      File.read(pathname.path)
    end

    def to_path
      pathname.path
    end
  end
end
