require 'sprockets/asset'
require 'sprockets/utils'

module Sprockets
  class ProcessedAsset < Asset
    attr_reader :required_assets

    def initialize(environment, logical_path, pathname)
      super

      start_time = Time.now.to_f
      context = blank_context

      @source         = context.evaluate(pathname)
      @required_paths = context._required_paths
      @required_assets = []

      unless @required_paths.include?(pathname.to_s)
        @required_paths << pathname.to_s
      end

      each_required_asset do |asset|
        @required_assets << asset
      end

      @dependency_paths = Set.new
      context._dependency_paths.each do |path|
        @dependency_paths << DependencyFile.new(path, environment.stat(path).mtime, environment.file_digest(path).hexdigest)
      end
      context._dependency_assets.each do |path|
        if path == self.pathname.to_s
          @dependency_paths << DependencyFile.new(pathname, mtime, digest)
        elsif required_asset = environment.find_asset(path, :bundle => false)
          @dependency_paths.merge(required_asset.dependency_paths)
        end
      end

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      logger.info "Compiled #{logical_path}  (#{elapsed_time}ms)  (pid #{Process.pid})"
    end

    attr_reader :source

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @source          = coder['source']
      @required_paths  = coder['required_paths'].map { |p| expand_root_path(p) }
      @required_assets = coder['required_paths'].map { |p|
        p = expand_root_path(p)
        p == pathname.to_s ? self : environment[p, :bundle => false]
      }
      @dependency_paths = Set.new(coder['dependency_paths'].map { |h|
        DependencyFile.new(expand_root_path(h['path']), h['mtime'], h['digest'])
      })
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super

      coder['source']           = source
      coder['required_paths']   = @required_paths.map { |p| relativize_root_path(p) }
      coder['dependency_paths'] = @dependency_paths.map { |d|
        { 'path' => relativize_root_path(d.pathname).to_s,
          'mtime' => d.mtime.iso8601,
          'digest' => d.digest }
      }
    end

    # Checks if Asset is stale by comparing the actual mtime and
    # digest to the inmemory model.
    def fresh?
      # Check freshness of all declared dependencies
      @dependency_paths.all? { |dep| dependency_fresh?(dep) }
    end

    # TODO: Hide this
    def each_required_asset(requires = Set.new, &block)
      return if requires.include?(self.pathname.to_s)
      requires << self.pathname.to_s

      paths = Set.new
      @required_paths.each do |path|
        next if paths.include?(path)

        if path == self.pathname.to_s
          paths << path
          yield self
        elsif required_asset = environment.find_asset(path, :bundle => false)
          required_asset.each_required_asset(requires) do |asset_dependency|
            paths << asset_dependency.pathname.to_s
            yield asset_dependency
          end
        end
      end
    end

    protected
      class DependencyFile < Struct.new(:pathname, :mtime, :digest)
        def initialize(pathname, mtime, digest)
          pathname = Pathname.new(pathname) unless pathname.is_a?(Pathname)
          mtime    = Time.parse(mtime) if mtime.is_a?(String)
          super
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

      # TODO: Get rid of this
      attr_reader :dependency_paths
  end
end
