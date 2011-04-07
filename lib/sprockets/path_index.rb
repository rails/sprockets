require 'sprockets/concatenated_asset'
require 'sprockets/errors'
require 'sprockets/pathname'
require 'sprockets/static_asset'

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

    def resolve(logical_path, options = {})
      if block_given?
        @trail.find(logical_path.to_s, options) do |path|
          yield Pathname.new(path)
        end

        @trail.find(Pathname.new(logical_path).index.to_s, options) do |path|
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
