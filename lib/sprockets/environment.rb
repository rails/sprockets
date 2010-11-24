require "hike"

module Sprockets
  class Environment
    DEFAULT_ENGINE_EXTENSIONS = %w( .coffee .erb .less .sass .scss .str )
    CONCATENATABLE_EXTENSIONS = %w( .css .js )

    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      engine_extensions.replace(DEFAULT_ENGINE_EXTENSIONS)
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

    def resolve(logical_path, options = {})
      if path = @trail.find(logical_path, options)
        Pathname.new(path)
      else
        raise FileNotFound, "couldn't find file '#{logical_path}'"
      end
    end

    def find_asset(logical_path)
      pathname = resolve(logical_path)

      if concatenatable?(pathname.format_extension)
        ConcatenatedAsset.new(self, pathname)
      else
        StaticAsset.new(pathname)
      end
    end

    alias_method :[], :find_asset

    protected
      def concatenatable?(format_extension)
        CONCATENATABLE_EXTENSIONS.include?(format_extension)
      end
  end
end
