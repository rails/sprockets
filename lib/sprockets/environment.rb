module Sprockets
  class Environment
    def initialize(root = ".")
      @trail = Hike::Trail.new(root)
      @trail.extensions.push(".coffee", ".less", ".scss", ".erb")
    end

    def root
      @trail.root
    end

    def paths
      @trail.paths
    end

    def find_asset(logical_path)
      if source_file = find_source_file(logical_path)
        Asset.new(self, source_file)
      else
        raise "couldn't find asset '#{asset_path}'"
      end
    end

    def find_source_file(logical_path)
      if path = @trail.find(logical_path)
        SourceFile.new(path)
      else
        raise "couldn't find source file '#{logical_path}'"
      end
    end
  end
end
