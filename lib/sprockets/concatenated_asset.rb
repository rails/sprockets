require 'sprockets/concatenation'
require 'sprockets/engine_pathname'
require 'sprockets/errors'

module Sprockets
  class ConcatenatedAsset
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def self.concatenatable?(pathname)
      CONCATENATABLE_EXTENSIONS.include?(EnginePathname.new(pathname).format_extension)
    end

    attr_reader :content_type, :format_extension
    attr_reader :mtime, :length, :digest

    def initialize(environment, pathname)
      engine_pathname   = EnginePathname.new(pathname)
      @content_type     = engine_pathname.content_type
      @format_extension = engine_pathname.format_extension

      concatenation = Concatenation.new(environment)
      concatenation.require(pathname)
      concatenation.compress!

      @source_paths = concatenation.paths
      @source       = concatenation.source
      @mtime        = concatenation.mtime
      @length       = concatenation.length
      @digest       = concatenation.digest
    end

    def each(&block)
      @source.each(&block)
    end

    def stale?
      @source_paths.any? { |p| mtime < File.mtime(p) }
    rescue Errno::ENOENT
      true
    end

    def to_s
      @source.join
    end

    def eql?(other)
      other.class == self.class &&
        other.content_type == self.content_type &&
        other.format_extension == self.format_extension &&
        other.source_paths == self.source_paths &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?
  end
end
