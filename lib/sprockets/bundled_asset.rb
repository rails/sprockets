require 'sprockets/asset'
require 'sprockets/errors'
require 'fileutils'
require 'set'
require 'zlib'

module Sprockets
  # `BundledAsset`s are used for files that need to be processed and
  # concatenated with other assets. Use for `.js` and `.css` files.
  class BundledAsset < Asset
    def initialize(environment, logical_path, filename)
      super

      processed_asset = environment.find_asset(filename, bundle: false)
      @required_assets = resolve_dependencies(environment, processed_asset, processed_asset.required_paths) -
        resolve_dependencies(environment, processed_asset, processed_asset.stubbed_paths)

      @dependency_paths = Set.new
      @required_assets.each do |asset|
        @dependency_paths.merge(asset.required_paths)
        @dependency_paths.merge(asset.dependency_paths)
      end
      @dependency_digest = environment.dependencies_hexdigest(@dependency_paths)

      # Explode Asset into parts and gather the dependency bodies
      @source = @required_assets.map { |asset| asset.to_s }.join

      # Run bundle processors on concatenated source
      @source = environment.process(
        environment.bundle_processors(content_type),
        filename,
        @source
      )[:data]

      @mtime  = @required_assets.map(&:mtime).max
      @length = Rack::Utils.bytesize(source)
      @digest = environment.digest.update(source).hexdigest
    end

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @required_assets = coder['required_paths'].map { |filename, digest|
        asset = environment.find_asset(filename, bundle: false)
        if asset.nil? || asset.digest != digest
          raise UnserializeError, "asset belongs to a stale environment"
        end
        asset
      }

      @source = coder['source']
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super

      coder['source'] = source
      coder['required_paths'] = @required_assets.map { |a| [a.filename, a.digest] }
    end

    # Expand asset into an `Array` of parts.
    def to_a
      @required_assets
    end

    private
      def resolve_dependencies(environment, processed_asset, paths)
        assets = Set.new

        paths.each do |path|
          if path == self.filename
            assets << processed_asset
          elsif asset = environment.find_asset(path, bundle: true)
            assets.merge(asset.to_a)
          else
            raise FileNotFound, "could not find #{path}"
          end
        end

        assets.to_a
      end
  end
end
