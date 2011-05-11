require 'sprockets/asset_pathname'
require 'digest/md5'
require 'set'
require 'time'

module Sprockets
  class ConcatenatedAsset
    attr_reader :pathname, :content_type
    attr_reader :mtime, :length, :digest
    attr_reader :dependencies, :dependency_paths
    attr_reader :body

    def initialize(environment, pathname)
      environment = environment
      context     = environment.context_class.new(environment, pathname)

      @pathname     = pathname
      @content_type = AssetPathname.new(pathname, environment).content_type

      @body = context.evaluate(pathname)

      compute_dependencies(environment, context)
      compute_dependency_paths(context)
      compute_source(environment, context)
    end

    def each
      yield @source
    end

    def stale?
      dependency_paths.any? { |p| mtime < File.mtime(p) }
    rescue Errno::ENOENT
      true
    end

    def to_s
      @source
    end

    def eql?(other)
      other.class == self.class &&
        other.content_type == self.content_type &&
        other.source_paths == self.source_paths &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    private
      def compute_dependencies(environment, context)
        @dependencies = []

        context.required_paths.each do |required_path|
          if required_path == pathname.to_s
            add_dependency(self)
          else
            environment.build_asset(required_path).dependencies.each do |asset|
              add_dependency(asset)
            end
          end
        end
        add_dependency(self)
      end

      def add_dependency(asset)
        unless @dependencies.any? { |dep| dep.pathname == asset.pathname }
          @dependencies << asset
        end
      end

      def compute_dependency_paths(context)
        @dependency_paths = Set.new
        @mtime = Time.at(0)

        depend_on(pathname)

        context.dependency_paths.each do |path|
          depend_on(path)
        end

        @dependencies.each do |dependency|
          dependency.dependency_paths.each do |path|
            depend_on(path)
          end
        end
      end

      def depend_on(path)
        if (mtime = File.mtime(path)) > @mtime
          @mtime = mtime
        end
        @dependency_paths << path
      end

      def compute_source(environment, context)
        source = ""
        @dependencies.each { |dependency| source << dependency.body }

        @source = context.evaluate(pathname, :data => source,
                    :engines => environment.filters(content_type))
        @length = Rack::Utils.bytesize(@source)
        @digest = Digest::MD5.hexdigest(@source)
      end
  end
end
