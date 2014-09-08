require 'fileutils'
require 'pathname'

module Sprockets
  class Asset
    attr_reader :logical_path

    # Private: Intialize Asset wrapper from attributes Hash.
    #
    # Asset wrappers should not be initialized directly, only
    # Environment#find_asset should vend them.
    #
    # attributes - Hash of ivars
    #
    # Returns Asset.
    def initialize(attributes = {})
      @attributes = attributes
      attributes.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    # Internal: Return all internal instance variables as a hash.
    #
    # Returns a Hash.
    def to_hash
      @attributes
    end

    # Public: Metadata accumulated from pipeline process.
    #
    # The API status of the keys is dependent on the pipeline processors
    # itself. So some values maybe considered public and others internal.
    # See the pipeline proccessor documentation itself.
    #
    # Returns Hash.
    attr_reader :metadata

    # Public: Returns String path of asset.
    attr_reader :filename

    # Deprecated: Use #filename instead.
    #
    # Returns Pathname.
    def pathname
      @pathname ||= Pathname.new(filename)
    end

    # Public: Return logical path with digest spliced in.
    #
    #   "foo/bar-37b51d194a7513e45b56f6524f2d51f2.js"
    #
    # Returns String.
    def digest_path
      logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
    end

    # Public: Returns String MIME type of asset. Returns nil if type is unknown.
    attr_reader :content_type

    # Deprecated: Expand asset into an `Array` of parts.
    #
    # Appending all of an assets body parts together should give you
    # the asset's contents as a whole.
    #
    # This allows you to link to individual files for debugging
    # purposes.
    #
    # Use Asset#source_paths instead. Keeping a full copy of the bundle's
    # processed assets in memory (and in cache) is expensive and redundant. The
    # common use case is to relink to the assets anyway. #source_paths provides
    # that reference.
    #
    # Returns Array of Assets.
    def to_a
      if metadata.key?(:required_asset_hashes)
        metadata[:required_asset_hashes].map do |hash|
          Asset.new(hash)
        end
      else
        [self]
      end
    end

    # Deprecated: Get all required Assets.
    #
    # See Asset#to_a
    #
    # Returns Array of Assets.
    def dependencies
      to_a.reject { |a| a.filename.eql?(self.filename) }
    end

    # Public: Array of required processed assets.
    #
    # This allows you to link to individual files for debugging
    # purposes.
    #
    # Examples
    #
    #   asset.source_paths #=>
    #   ["jquery-729a810640240adfd653c3d958890cfc4ec0ea84.js",
    #    "users-08ae3439d6c8fe911445a2fb6e07ee1dc12ca599.js",
    #    "application-b5df367abb741cac6526b05a726e9e8d7bd863d2.js"]
    #
    # Returns an Array of String digest paths.
    def source_paths
      to_a.map(&:digest_path)
    end

    # Public: Return `String` of concatenated source.
    #
    # Returns String.
    def source
      if defined? @source
        @source
      else
        # File is read everytime to avoid memory bloat of large binary files
        File.open(filename, 'rb') { |f| f.read }
      end
    end

    # Public: Alias for #source.
    #
    # Returns String.
    def to_s
      source
    end

    # Public: HTTP encoding for Asset, "deflate", "gzip", etc.
    #
    # Note: This is not the Ruby Encoding of the source. See Asset#charset.
    #
    # Returns a String or nil if encoding is "identity".
    def encoding
      metadata[:encoding]
    end

    # Public: Get charset of source.
    #
    # Returns a String charset name or nil if binary.
    attr_reader :charset

    # Public: Returns Integer length of source.
    attr_reader :length
    alias_method :bytesize, :length

    # Public: Returns Time of the last time the source was modified.
    #
    # Time resolution is normalized to the nearest second.
    #
    # Returns Time.
    def mtime
      Time.at(@mtime)
    end

    # Public: Returns String hexdigest of source.
    attr_reader :digest

    # Pubic: ETag String of Asset.
    alias_method :etag, :digest

    # Public: Add enumerator to allow `Asset` instances to be used as Rack
    # compatible body objects.
    #
    # block
    #   part - String body chunk
    #
    # Returns nothing.
    def each
      yield to_s
    end

    # Public: Save asset to disk.
    #
    # filename - String target
    #
    # Returns nothing.
    def write_to(filename)
      FileUtils.mkdir_p File.dirname(filename)

      PathUtils.atomic_write(filename) do |f|
        f.write source
      end

      # Set mtime correctly
      File.utime(mtime, mtime, filename)

      nil
    end

    # Public: Pretty inspect
    #
    # Returns String.
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "filename=#{filename.inspect}, " +
        "mtime=#{mtime.inspect}, " +
        "digest=#{digest.inspect}" +
        ">"
    end

    # Public: Implements Object#hash so Assets can be used as a Hash key or
    # in a Set.
    #
    # Returns Integer hash of digest.
    def hash
      digest.hash
    end

    # Public: Compare assets.
    #
    # Assets are equal if they share the same path, mtime and digest.
    #
    # Returns true or false.
    def eql?(other)
      other.class == self.class &&
        other.filename == self.filename &&
        other.mtime.to_i == self.mtime.to_i &&
        other.digest == self.digest
    end
    alias_method :==, :eql?
  end
end
