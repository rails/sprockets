require 'sprockets/engine_pathname'
require 'sprockets/static_asset'
require 'pathname'

module Sprockets
  class StaticIndex
    attr_reader :root, :engines

    def initialize(root, engines)
      @root    = root ? Pathname.new(root) : nil
      @engines = engines
      @entries = {}
      @assets  = {}
    end

    def find_asset(logical_path)
      return unless @root

      logical_path = logical_path.to_s.sub(/^\//, '')

      if @assets.key?(logical_path)
        return @assets[logical_path]
      end

      pathname = Pathname.new(root.join(logical_path))
      engine_pathname = EnginePathname.new(pathname, engines)

      entries = entries(pathname.dirname)

      if entries.empty?
        @assets[logical_path] = nil
        return nil
      end

      if !Utils.path_fingerprint(pathname)
        pattern = /^#{Regexp.escape(engine_pathname.basename_without_extensions.to_s)}
                   -[0-9a-f]{7,40}
                   #{Regexp.escape(engine_pathname.extensions.join)}$/x

        entries.each do |filename|
          if filename.to_s =~ pattern
            asset = StaticAsset.new(pathname.dirname.join(filename), engines)
            @assets[logical_path] = asset
            return asset
          end
        end
      end

      if entries.include?(pathname.basename) && pathname.file?
        asset = StaticAsset.new(pathname, engines)
        @assets[logical_path] = asset
        return asset
      end

      @assets[logical_path] = nil
      nil
    end

    protected
      def entries(pathname)
        @entries[pathname.to_s] ||= pathname.entries.reject { |entry| entry.to_s =~ /^\.\.?$/ }
      rescue Errno::ENOENT
        @entries[pathname.to_s] = []
      end
  end
end
