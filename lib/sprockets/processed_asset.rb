require 'sprockets/asset'
require 'sprockets/utils'

module Sprockets
  class ProcessedAsset < Asset
    attr_reader :required_assets

    def initialize(environment, logical_path, pathname)
      super

      start_time = Time.now.to_f

      context = environment.context_class.new(environment, logical_path, pathname)
      @source = context.evaluate(pathname)

      @required_assets  = []
      @dependency_paths = Set.new

      (context._required_paths + [pathname.to_s]).each do |path|
        if path == self.pathname.to_s
          @required_assets << self unless @required_assets.include?(self)
        elsif asset = environment.find_asset(path, :bundle => false)
          asset.required_assets.each do |asset_dependency|
            @required_assets << asset_dependency unless @required_assets.include?(asset_dependency)
          end
        end
      end

      context._dependency_paths.each do |path|
        @dependency_paths << DependencyFile.new(path, environment.stat(path).mtime, environment.file_digest(path).hexdigest)
      end

      context._dependency_assets.each do |path|
        if path == self.pathname.to_s
          @dependency_paths << DependencyFile.new(pathname, mtime, digest)
        elsif asset = environment.find_asset(path, :bundle => false)
          @dependency_paths.merge(asset.dependency_paths)
        end
      end

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      environment.logger.info "Compiled #{logical_path}  (#{elapsed_time}ms)  (pid #{Process.pid})"
    end

    attr_reader :source

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @source          = coder['source']
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
      coder['required_paths']   = required_assets.map { |a|
        relativize_root_path(a.pathname).to_s
      }
      coder['dependency_paths'] = @dependency_paths.map { |d|
        { 'path' => relativize_root_path(d.pathname).to_s,
          'mtime' => d.mtime.iso8601,
          'digest' => d.digest }
      }
    end

    # Checks if Asset is stale by comparing the actual mtime and
    # digest to the inmemory model.
    def fresh?(environment)
      # Check freshness of all declared dependencies
      @dependency_paths.all? { |dep| dependency_fresh?(environment, dep) }
    end

    protected
      attr_reader :dependency_paths

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
  end
end
