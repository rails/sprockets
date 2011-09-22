require 'sprockets/asset'
require 'sprockets/errors'
require 'fileutils'
require 'set'
require 'zlib'

module Sprockets
  class DependencyFile < Struct.new(:pathname, :mtime, :digest)
    def initialize(pathname, mtime, digest)
      pathname = Pathname.new(pathname) unless pathname.is_a?(Pathname)
      mtime    = Time.parse(mtime) if mtime.is_a?(String)
      super
    end

    def to_hash
      { 'path' => pathname.to_s, 'mtime' => mtime.iso8601, 'digest' => digest }
    end

    def eql?(other)
      other.is_a?(DependencyFile) &&
        pathname.eql?(other.pathname) &&
        mtime.eql?(other.mtime) &&
        digest.eql?(other.digest)
    end

    def hash
      pathname.to_s.hash
    end
  end

  # `BundledAsset`s are used for files that need to be processed and
  # concatenated with other assets. Use for `.js` and `.css` files.
  class BundledAsset < Asset
    attr_reader :source

    def initialize(environment, logical_path, pathname)
      super(environment, logical_path, pathname)

      @self_asset = @environment.find_asset(pathname, :bundle => false)

      @body = @self_asset.source

      @assets = []
      @dependency_paths = Set.new
      @self_asset.each_required_asset do |asset|
        raise ArgumentError unless asset.is_a?(ProcessedAsset)
        @assets << asset
        @dependency_paths.merge(asset.send(:dependency_paths))
      end

      @source = build_source
      @mtime  = to_a.map { |asset| asset.mtime }.max
      @length = Rack::Utils.bytesize(source)
      @digest = environment.digest.update(source).hexdigest
    end

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @self_asset = @environment.find_asset(pathname, :bundle => false)

      @body   = coder['body']
      @source = coder['source']

      @dependency_paths = Set.new(coder['dependency_paths'].map { |h|
        DependencyFile.new(h['path'], h['mtime'], h['digest'])
      })

      @assets = coder['asset_paths'].map { |p|
        p = expand_root_path(p)
        p == pathname.to_s ? @self_asset : environment[p, :bundle => false]
      }
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super

      coder['body']   = body
      coder['source'] = source
      coder['asset_paths'] = to_a.map { |a| relativize_root_path(a.pathname) }
      coder['dependency_paths'] = @dependency_paths.map(&:to_hash)
    end

    # Get asset's own processed contents. Excludes any of its required
    # dependencies but does run any processors or engines on the
    # original file.
    def body
      @body
    end

    # Return an `Array` of `Asset` files that are declared dependencies.
    def dependencies
      to_a.reject { |a| a.eql?(@self_asset) }
    end

    # Expand asset into an `Array` of parts.
    def to_a
      @assets
    end

    # Checks if Asset is stale by comparing the actual mtime and
    # digest to the inmemory model.
    def fresh?
      # Check freshness of all dependencies
      @dependency_paths.all? { |dep| dependency_fresh?(dep) }
    end

    protected
      attr_reader :dependency_paths

    private
      def build_source
        data = ""

        # Explode Asset into parts and gather the dependency bodies
        to_a.each { |dependency| data << dependency.to_s }

        # Run bundle processors on concatenated source
        blank_context.evaluate(pathname, :data => data,
          :processors => environment.bundle_processors(content_type))
      end
  end
end
