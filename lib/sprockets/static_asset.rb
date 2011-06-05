require 'digest/md5'
require 'multi_json'
require 'time'

module Sprockets
  class StaticAsset
    attr_reader :logical_path, :pathname
    attr_reader :content_type, :mtime, :length, :digest

    def self.from_json(environment, json)
      asset = allocate
      asset.initialize_json(environment, json)
      asset
    end

    def initialize(environment, logical_path, pathname, digest = nil)
      @logical_path = logical_path.to_s
      @pathname     = Pathname.new(pathname)
      @content_type = environment.content_type_of(pathname)

      @mtime  = @pathname.mtime
      @length = @pathname.size
      @digest = digest || Digest::MD5.file(pathname).hexdigest
    end

    def initialize_json(environment, json)
      @environment = environment

      hash = MultiJson.decode(json)

      @logical_path = hash['logical_path'].to_s
      @pathname     = Pathname.new(hash['pathname'])
      @content_type = hash['content_type']
      @mtime        = Time.parse(hash['mtime'])
      @length       = hash['length']
      @digest       = hash['digest']
    end

    def dependencies
      []
    end

    def dependencies?
      false
    end

    def to_a
      [self]
    end

    def body
      to_s
    end

    def stale?
      mtime < pathname.mtime
    rescue Errno::ENOENT
      true
    end

    def each
      yield to_s
    end

    def to_path
      pathname.to_s
    end

    def to_s
      pathname.open('rb') { |f| f.read }
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    def as_json
      {
        'logical_path' => logical_path,
        'pathname'     => pathname.to_s,
        'content_type' => content_type,
        'mtime'        => mtime,
        'digest'       => digest,
        'length'       => length
      }
    end

    def to_json
      MultiJson.encode(as_json)
    end
  end
end
