require 'sprockets/errors'
require 'digest/md5'
require 'set'
require 'time'

module Sprockets
  class BundledAsset
    attr_reader :logical_path, :pathname
    attr_reader :content_type, :mtime
    attr_reader :body

    def initialize(environment, logical_path, pathname, options)
      @environment  = environment
      @context      = environment.context_class.new(environment, logical_path.to_s, pathname)

      @logical_path = logical_path.to_s
      @pathname     = pathname
      @content_type = environment.content_type_of(pathname)

      @assets       = []
      @source       = nil
      @body         = context.evaluate(pathname)

      index    = options[:_environment] || options[:_index] || environment
      requires = options[:_requires] || []
      if requires.include?(pathname.to_s)
        raise CircularDependencyError, "#{pathname} has already been required"
      end
      requires << pathname.to_s

      compute_dependencies!(index, requires)
      compute_dependency_paths!
    end

    def source
      @source ||= begin
        data = ""
        to_a.each { |dependency| data << dependency.body }
        context.evaluate(pathname, :data => data,
          :engines => environment.bundle_processors(content_type))
      end
    end

    def length
      @length ||= Rack::Utils.bytesize(source)
    end

    def digest
      @digest ||= Digest::MD5.hexdigest(source)
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
      yield source
    end

    def stale?
      dependency_paths.any? { |p| mtime < File.mtime(p) }
    rescue Errno::ENOENT
      true
    end

    def to_s
      source
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      attr_reader :environment, :context, :dependency_paths

    private
      def compute_dependencies!(index, requires)
        options = { :_requires => requires }
        context._required_paths.each do |required_path|
          if required_path == pathname.to_s
            add_dependency(self)
          else
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

      def compute_dependency_paths!
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
  end
end
