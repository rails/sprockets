require 'sprockets/asset'
require 'sprockets/fileutils'
require 'set'

module Sprockets
  class ProcessedAsset < Asset
    def initialize(environment, logical_path, filename)
      super

      start_time = Time.now.to_f

      encoding = environment.encoding_for_mime_type(content_type)
      data     = FileUtils.read_unicode(filename, encoding)

      result = environment.process(
        environment.attributes_for(filename).processors,
        filename,
        data
      )
      @source = result[:data]

      @length = source.bytesize
      @digest = environment.digest.update(source).hexdigest

      @required_assets = build_required_assets(environment, result)
      @dependency_paths, @dependency_mtime = build_dependency_paths(environment, result)
      @dependency_digest = environment.dependencies_hexdigest(@dependency_paths)

      elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
      environment.logger.debug "Compiled #{logical_path}  (#{elapsed_time}ms)  (pid #{Process.pid})"
    end

    attr_reader :source

    # Initialize `BundledAsset` from serialized `Hash`.
    def init_with(environment, coder)
      super

      @source = coder['source']

      @required_assets = coder['required_paths'].map { |p|
        unless environment.paths.detect { |path| p[path] }
          raise UnserializeError, "#{p} isn't in paths"
        end

        p == filename ? self : environment.find_asset(p, bundle: false)
      }
    end

    # Serialize custom attributes in `BundledAsset`.
    def encode_with(coder)
      super

      coder['source'] = source
      coder['required_paths'] = required_assets.map(&:filename)
    end

    private
      def build_required_assets(environment, result)
        resolve_dependencies(environment, result[:required_paths] + [filename]) -
          resolve_dependencies(environment, result[:stubbed_assets])
      end

      def resolve_dependencies(environment, paths)
        assets = Set.new

        paths.each do |path|
          if path == self.filename
            assets << self
          elsif asset = environment.find_asset(path, bundle: false)
            assets.merge(asset.required_assets)
          end
        end

        assets.to_a
      end

      def build_dependency_paths(environment, result)
        mtimes = []

        paths = Set.new

        result[:dependency_paths].map do |path|
          mtimes << environment.stat(path).mtime
          paths << path
        end

        result[:dependency_assets].flat_map do |path|
          if path == self.filename
            mtimes << environment.stat(path).mtime
            paths << path
          elsif asset = environment.find_asset(path, bundle: false)
            mtimes << asset.dependency_mtime
            paths.merge(asset.dependency_paths)
          end
        end

        return paths, mtimes.max
      end
  end
end
