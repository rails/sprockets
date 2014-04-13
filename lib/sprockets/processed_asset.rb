require 'sprockets/asset'
require 'sprockets/fileutils'
require 'set'

module Sprockets
  class ProcessedAsset < Asset
    def initialize(environment, logical_path, pathname)
      super

      start_time = Time.now.to_f

      mime_type = environment.mime_types(File.extname(pathname))
      encoding  = environment.encoding_for_mime_type(mime_type)
      data      = FileUtils.read_unicode(pathname, encoding)

      result = environment.process(
        environment.attributes_for(pathname).processors,
        pathname.to_s,
        logical_path,
        data
      )
      @source = result[:data]

      @length = source.bytesize
      @digest = environment.digest.update(source).hexdigest

      build_required_assets(environment, result)
      @dependency_paths = build_dependency_paths(environment, result)

      @dependency_digest = compute_dependency_digest(environment)

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      environment.logger.debug "Compiled #{logical_path}  (#{elapsed_time}ms)  (pid #{Process.pid})"
    end

    # Interal: Used to check equality
    attr_reader :dependency_digest

    attr_reader :source

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @source = coder['source']
      @dependency_digest = coder['dependency_digest']

      @required_assets = coder['required_paths'].map { |p|
        p = expand_root_path(p)

        unless environment.paths.detect { |path| p[path] }
          raise UnserializeError, "#{p} isn't in paths"
        end

        p == pathname.to_s ? self : environment.find_asset(p, bundle: false)
      }
      @dependency_paths = coder['dependency_paths'].map { |h|
        DependencyFile.new(expand_root_path(h['path']), h['mtime'], h['digest'])
      }
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super

      coder['source'] = source
      coder['dependency_digest'] = dependency_digest

      coder['required_paths'] = required_assets.map { |a|
        relativize_root_path(a.pathname).to_s
      }
      coder['dependency_paths'] = dependency_paths.map { |d|
        { 'path' => relativize_root_path(d.pathname).to_s,
          'mtime' => d.mtime.iso8601,
          'digest' => d.digest }
      }
    end

    # Checks if Asset is stale by comparing the actual mtime and
    # digest to the inmemory model.
    def fresh?(environment)
      # Check freshness of all declared dependencies
      @dependency_paths.all? do |dep|
        dep.digest == environment.file_hexdigest(dep.pathname.to_s)
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

    private
      def build_required_assets(environment, result)
        @required_assets = resolve_dependencies(environment, result[:required_paths] + [pathname.to_s]) -
          resolve_dependencies(environment, result[:stubbed_assets].to_a)
      end

      def resolve_dependencies(environment, paths)
        assets = Set.new

        paths.each do |path|
          if path == self.pathname.to_s
            assets << self
          elsif asset = environment.find_asset(path, bundle: false)
            asset.required_assets.each do |asset_dependency|
              assets << asset_dependency
            end
          end
        end

        assets.to_a
      end

      def build_dependency_paths(environment, result)
        paths = result[:dependency_paths].map do |path|
          DependencyFile.new(path, environment.stat(path).mtime, environment.file_hexdigest(path))
        end

        assets = result[:dependency_assets].flat_map do |path|
          if path == self.pathname.to_s
            DependencyFile.new(pathname, environment.stat(path).mtime, environment.file_hexdigest(path))
          elsif asset = environment.find_asset(path, bundle: false)
            asset.dependency_paths
          end
        end

        paths.concat(assets).uniq
      end

      def compute_dependency_digest(environment)
        required_assets.inject(environment.digest) { |digest, asset|
          digest.update asset.digest
        }.hexdigest
      end
  end
end
