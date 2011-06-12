require 'sprockets/bundled_asset'
require 'sprockets/errors'
require 'sprockets/static_asset'
require 'pathname'

module Sprockets
  module Trail
    def self.included(base)
      base.instance_eval do
        attr_reader :trail
        protected :trail
      end
    end

    def root
      trail.root.dup
    end

    def paths
      trail.paths.dup
    end

    def append_path(path)
      expire_index!
      @trail.paths.push(path)
    end

    def prepend_path(path)
      expire_index!
      @trail.paths.unshift(path)
    end

    def clear_paths
      expire_index!
      @trail.paths.clear
    end

    def extensions
      trail.extensions.dup
    end

    def resolve(logical_path, options = {})
      if block_given?
        trail.find(logical_path.to_s, attributes_for(logical_path).index_path, options) do |path|
          yield Pathname.new(path)
        end
      else
        resolve(logical_path, options) do |pathname|
          return pathname
        end
        raise FileNotFound, "couldn't find file '#{logical_path}'"
      end
    end

    def find_asset(path, options = {})
      pathname = Pathname.new(path)

      if pathname.absolute?
        build_asset(detect_logical_path(path).to_s, pathname, options)
      else
        find_asset_in_static_root(pathname) ||
          find_asset_in_path(pathname, options)
      end
    end

    def [](*args)
      find_asset(*args)
    end

    protected
      def find_asset_in_path(logical_path, options = {})
        if fingerprint = attributes_for(logical_path).path_fingerprint
          pathname = resolve(logical_path.to_s.sub("-#{fingerprint}", ''))
        else
          pathname = resolve(logical_path)
        end
      rescue FileNotFound
        nil
      else
        asset = build_asset(logical_path, pathname, options)

        if fingerprint && fingerprint != asset.digest
          logger.error "Nonexistent asset #{logical_path} @ #{fingerprint}"
          asset = nil
        end

        asset
      end

      def build_asset(logical_path, pathname, options)
        pathname = Pathname.new(pathname)

        if processors(content_type_of(pathname)).any?
          BundledAsset.new(self, logical_path, pathname, options)
        else
          StaticAsset.new(self, logical_path, pathname)
        end
      end

      def entries(pathname)
        pathname.entries.reject { |entry| entry.to_s =~ /^\.\.?$/ }
      rescue Errno::ENOENT
        []
      end

    private
      def paths_hash
        trail.paths.join(',')
      end

      def detect_logical_path(filename)
        if root_path = paths.detect { |path| filename.to_s[path] }
          root_pathname = Pathname.new(root_path)
          logical_path  = Pathname.new(filename).relative_path_from(root_pathname)
          attributes_for(logical_path).without_engine_extensions
        end
      end
  end
end
