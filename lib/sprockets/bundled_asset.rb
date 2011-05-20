require 'sprockets/asset_pathname'
require 'sprockets/errors'
require 'digest/md5'
require 'set'
require 'time'

module Sprockets
  class BundledAsset
    attr_reader :logical_path, :pathname
    attr_reader :content_type, :mtime, :length, :digest
    attr_reader :body

    def initialize(environment, logical_path, pathname, options)
      environment = environment
      context     = environment.context_class.new(environment, logical_path.to_s, pathname)

      @logical_path = logical_path.to_s
      @pathname     = pathname
      @content_type = AssetPathname.new(pathname, environment).content_type

      @body = context.evaluate(pathname)

      requires = options[:_requires] ||= []
      if requires.include?(pathname.to_s)
        raise CircularDependencyError, "#{pathname} has already been required"
      end
      requires << pathname.to_s

      @assets = []

      compute_dependencies(environment, context, options)
      compute_dependency_paths(context)
      compute_source(environment, context)
    end

    def dependencies?
      dependencies.any?
    end

    def dependencies
      @assets - [self]
    end

    def to_a
      @assets
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
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      attr_reader :dependency_paths

    private
      def compute_dependencies(environment, context, options)
        context._required_paths.each do |required_path|
          if required_path == pathname.to_s
            add_dependency(self)
          else
            index = (options[:_environment] || options[:_index] || environment)
            index[required_path, options].to_a.each do |asset|
              add_dependency(asset)
            end
          end
        end
        add_dependency(self)
      end

      def add_dependency(asset)
        unless to_a.any? { |dep| dep.pathname == asset.pathname }
          @assets << asset
        end
      end

      def compute_dependency_paths(context)
        @dependency_paths = Set.new
        @mtime = Time.at(0)

        depend_on(pathname)

        context._dependency_paths.each do |path|
          depend_on(path)
        end

        to_a.each do |dependency|
          dependency.dependency_paths.each do |path|
            depend_on(path)
          end
        end
      end

      def depend_on(path)
        if (mtime = File.mtime(path)) > @mtime
          @mtime = mtime
        end
        dependency_paths << path
      end

      def compute_source(environment, context)
        source = ""
        to_a.each { |dependency| source << dependency.body }

        @source = context.evaluate(pathname, :data => source,
                    :engines => environment.bundle_processors(content_type))
        @length = Rack::Utils.bytesize(@source)
        @digest = Digest::MD5.hexdigest(@source)
      end
  end
end
