require 'hike'
require 'thread'

module Sprockets
  class Environment
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      engine_extensions.replace(DEFAULT_ENGINE_EXTENSIONS + CONCATENATABLE_EXTENSIONS)

      @cache = {}
      @lock  = nil
    end

    def multithread
      @lock ? true : false
    end

    def multithread=(val)
      @lock = val ? Mutex.new : nil
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def engine_extensions
      @trail.extensions
    end

    def server
      @server ||= Server.new(self)
    end

    def resolve(logical_path, options = {})
      if block_given?
        @trail.find(logical_path, options) do |path|
          yield Pathname.new(path)
        end
      else
        if path = @trail.find(logical_path, options)
          Pathname.new(path)
        else
          raise FileNotFound, "couldn't find file '#{logical_path}'"
        end
      end
    end

    def build_asset(logical_path)
      begin
        pathname = resolve(logical_path)
      rescue FileNotFound
        nil
      else
        if concatenatable?(pathname.format_extension)
          ConcatenatedAsset.new(self, pathname)
        else
          StaticAsset.new(pathname)
        end
      end
    end

    def find_fresh_asset(logical_path)
      if (asset = @cache[logical_path]) && !asset.stale?
        asset
      else
        nil
      end
    end

    def find_asset(logical_path)
      if asset = find_fresh_asset(logical_path)
        asset
      elsif @lock
        @lock.synchronize do
          if asset = find_fresh_asset(logical_path)
            asset
          else
            @cache[logical_path] = build_asset(logical_path)
          end
        end
      else
        @cache[logical_path] = build_asset(logical_path)
      end
    end

    alias_method :[], :find_asset

    protected
      def concatenatable?(format_extension)
        CONCATENATABLE_EXTENSIONS.include?(format_extension)
      end
  end
end
