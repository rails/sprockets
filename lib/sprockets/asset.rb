require 'pathname'
require 'set'
require 'sprockets/fileutils'
require 'time'

module Sprockets
  # `Asset` is the base class for `BundledAsset` and `StaticAsset`.
  class Asset
    # Internal initializer to load `Asset` from serialized `Hash`.
    def self.from_hash(environment, hash)
      return unless hash.is_a?(Hash)

      klass = case hash['class']
        when 'BundledAsset'
          BundledAsset
        when 'ProcessedAsset'
          ProcessedAsset
        when 'StaticAsset'
          StaticAsset
        else
          nil
        end

      if klass
        asset = klass.allocate
        asset.init_with(environment, hash)
        asset
      end
    rescue UnserializeError
      nil
    end

    attr_reader :logical_path, :filename
    attr_reader :content_type, :mtime, :length, :digest
    alias_method :bytesize, :length

    def initialize(environment, logical_path, filename)
      raise ArgumentError, "Asset logical path has no extension: #{logical_path}" if File.extname(logical_path) == ""

      @root         = environment.root
      @logical_path = logical_path.to_s
      @filename     = filename
      @content_type = environment.content_type_of(filename)
      # drop precision to 1 second, same pattern followed elsewhere
      @mtime        = Time.at(environment.stat(filename).mtime.to_i)
      @length       = environment.stat(filename).size
      @digest       = environment.digest.file(filename).hexdigest

      @dependency_digest = environment.dependencies_hexdigest(dependency_paths)
    end

    # Initialize `Asset` from serialized `Hash`.
    def init_with(environment, coder)
      @root = environment.root

      @logical_path = coder['logical_path']
      @filename     = coder['filename']
      @content_type = coder['content_type']
      @digest       = coder['digest']

      if mtime = coder['mtime']
        @mtime = Time.at(mtime)
      end

      if length = coder['length']
        # Convert length to an `Integer`
        @length = Integer(length)
      end

      @dependency_paths  = Set.new(coder['dependency_paths'])
      @dependency_mtime  = Time.at(coder['dependency_mtime'])
      @dependency_digest = coder['dependency_digest']
    end

    # Copy serialized attributes to the coder object
    def encode_with(coder)
      coder['class']        = self.class.name.sub(/Sprockets::/, '')
      coder['logical_path'] = logical_path
      coder['filename']     = filename
      coder['content_type'] = content_type
      coder['mtime']        = mtime.to_i
      coder['length']       = length
      coder['digest']       = digest

      coder['dependency_paths']  = dependency_paths.to_a
      coder['dependency_mtime']  = dependency_mtime.to_i
      coder['dependency_digest'] = dependency_digest
    end

    def pathname
      @pathname ||= Pathname.new(filename)
    end

    # Return logical path with digest spliced in.
    #
    #   "foo/bar-37b51d194a7513e45b56f6524f2d51f2.js"
    #
    def digest_path
      logical_path.sub(/\.(\w+)$/) { |ext| "-#{digest}#{ext}" }
    end

    # Return an `Array` of `Asset` files that are declared dependencies.
    def dependencies
      []
    end

    # Expand asset into an `Array` of parts.
    #
    # Appending all of an assets body parts together should give you
    # the asset's contents as a whole.
    #
    # This allows you to link to individual files for debugging
    # purposes.
    def to_a
      [self]
    end

    # `body` is aliased to source by default if it can't have any dependencies.
    def body
      source
    end

    # Return `String` of concatenated source.
    def to_s
      source
    end

    # Add enumerator to allow `Asset` instances to be used as Rack
    # compatible body objects.
    def each
      yield to_s
    end

    # Save asset to disk.
    def write_to(filename, options = {})
      # Gzip contents if filename has '.gz'
      options[:compress] ||= File.extname(filename) == '.gz'

      ::FileUtils.mkdir_p File.dirname(filename)

      FileUtils.atomic_write(filename) do |f|
        if options[:compress]
          # Run contents through `Zlib`
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime.to_i
          gz.write to_s
          gz.close
        else
          # Write out as is
          f.write to_s
        end
      end

      # Set mtime correctly
      File.utime(mtime, mtime, filename)

      nil
    ensure
      # Ensure tmp file gets cleaned up
      ::FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
    end

    # Pretty inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "filename=#{filename.inspect}, " +
        "mtime=#{mtime.inspect}, " +
        "digest=#{digest.inspect}" +
        ">"
    end

    def hash
      digest.hash
    end

    # Assets are equal if they share the same path, mtime and digest.
    def eql?(other)
      other.class == self.class &&
        other.logical_path == self.logical_path &&
        other.mtime.to_i == self.mtime.to_i &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      # Internal: String paths that are marked as dependencies after processing.
      #
      # Default to an `Set` with self.
      def dependency_paths
        @dependency_paths ||= Set.new([self.filename])
      end

      def dependency_mtime
        @dependency_mtime ||= @mtime
      end

      attr_reader :dependency_digest

      # Internal: `ProccessedAsset`s that are required after processing.
      #
      # Default to an empty `Array`.
      def required_assets
        @required_assets ||= []
      end
  end
end
