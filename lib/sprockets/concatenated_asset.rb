require 'sprockets/asset_pathname'
require 'sprockets/concatenation'

module Sprockets
  class ConcatenatedAsset
    attr_reader :content_type
    attr_reader :mtime, :length, :digest

    def initialize(environment, pathname)
      @content_type = AssetPathname.new(pathname, environment).content_type

      concatenation = Concatenation.new(environment, pathname)
      concatenation.require(pathname)
      concatenation.post_process!

      @source_paths = concatenation.paths
      @mtime        = concatenation.mtime
      @length       = concatenation.length
      @digest       = concatenation.digest
      @source       = concatenation.to_s
    end

    def each
      yield @source
    end

    def stale?
      @source_paths.any? { |p| mtime < File.mtime(p) }
    rescue Errno::ENOENT
      true
    end

    def to_s
      @source
    end

    def eql?(other)
      other.class == self.class &&
        other.content_type == self.content_type &&
        other.source_paths == self.source_paths &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?
  end
end
