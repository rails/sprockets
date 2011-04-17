require 'sprockets/concatenated_asset'
require 'sprockets/errors'
require 'sprockets/pathname'
require 'sprockets/static_asset'
require 'set'

module Sprockets
  class PathIndex
    attr_reader :logger, :css_compressor, :js_compressor

    def initialize(environment, trail)
      @logger         = environment.logger
      @css_compressor = environment.css_compressor
      @js_compressor  = environment.js_compressor

      @trail  = trail.index
      @assets = {}
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def pathnames
      paths.map { |path| Pathname.new(path) }
    end

    def engine_extensions
      @trail.extensions
    end

    def files
      files = Set.new
      pathnames.each do |base_pathname|
        Dir["#{base_pathname}/**/*"].each do |filename|
          logical_path = Pathname.new(filename).relative_path_from(base_pathname)
          files << Pathname.new(logical_path).without_engine_extensions
        end
      end
      files
    end

    def resolve(logical_path, options = {})
      if block_given?
        index_path = Pathname.new(logical_path).index.to_s
        @trail.find(logical_path.to_s, index_path, options) do |path|
          yield Pathname.new(path)
        end
      else
        resolve(logical_path, options) do |pathname|
          return pathname
        end
        raise FileNotFound, "couldn't find file '#{logical_path}'"
      end
    end

    def find_asset(logical_path)
      if @assets.key?(logical_path.to_s)
        return @assets[logical_path.to_s]
      end

      if fingerprint = logical_path.fingerprint
        pathname = resolve(logical_path.to_s.sub("-#{fingerprint}", ''))
      else
        pathname = resolve(logical_path)
      end
    rescue FileNotFound
      nil
    else
      if ConcatenatedAsset.concatenatable?(pathname)
        logger.info "[Sprockets] #{logical_path} building"
        asset = ConcatenatedAsset.new(self, pathname)
      else
        asset = StaticAsset.new(pathname)
      end

      if fingerprint && fingerprint != asset.digest
        logger.error "[Sprockets] #{logical_path} #{fingerprint} nonexistent"
        asset = nil
      end

      @assets[logical_path.to_s] = asset
      asset
    end
  end
end
