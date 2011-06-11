require 'sprockets/errors'
require 'multi_json'
require 'set'
require 'time'

module Sprockets
  class BundledAsset
    attr_reader :environment
    attr_reader :logical_path, :pathname, :mtime, :body

    def self.from_json(environment, json, options = {})
      asset = allocate
      asset.initialize_json(environment, json, options)
      asset
    end

    def initialize(environment, logical_path, pathname, options)
      @environment = environment

      @logical_path = logical_path.to_s
      @pathname     = pathname

      @assets = []
      @source = nil
      @body   = context.evaluate(pathname)

      requires = options[:_requires] ||= []
      if requires.include?(pathname.to_s)
        raise CircularDependencyError, "#{pathname} has already been required"
      end
      requires << pathname.to_s

      compute_dependencies!(environment, options)
      compute_dependency_paths!
    end

    def initialize_json(environment, json, options)
      @environment = environment

      hash = MultiJson.decode(json)

      @logical_path = hash['logical_path'].to_s
      @pathname     = Pathname.new(hash['pathname'])
      @mtime        = Time.parse(hash['mtime'])
      @body         = hash['body']
      @source       = hash['source']
      @content_type = hash['content_type']
      @length       = hash['length']
      @digest       = hash['digest']
      @assets       = hash['asset_paths'].map { |p| p == pathname.to_s ? self : environment[p, options] }
      @dependency_paths = hash['dependency_paths']
    end

    def source
      @source ||= begin
        data = ""
        to_a.each { |dependency| data << dependency.body }
        context.evaluate(pathname, :data => data,
          :processors => environment.bundle_processors(content_type))
      end
    end

    def content_type
      @content_type ||= environment.content_type_of(pathname)
    end

    def length
      @length ||= Rack::Utils.bytesize(source)
    end

    def digest
      @digest ||= environment.digest.update(source).hexdigest
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

    def as_json
      {
        'logical_path'     => logical_path,
        'pathname'         => pathname.to_s,
        'content_type'     => content_type,
        'mtime'            => mtime,
        'body'             => body,
        'source'           => source,
        'digest'           => digest,
        'length'           => length,
        'asset_paths'      => to_a.map(&:pathname).map(&:to_s),
        'dependency_paths' => dependency_paths
      }
    end

    def to_json
      MultiJson.encode(as_json)
    end

    protected
      attr_reader :dependency_paths

      def context
        @context ||= environment.context_class.new(environment, logical_path.to_s, pathname)
      end

    private
      def compute_dependencies!(environment, options)
        context._required_paths.each do |required_path|
          if required_path == pathname.to_s
            add_dependency(self)
          else
            environment[required_path, options].to_a.each do |asset|
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
        @dependency_paths = []
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
        unless dependency_paths.include?(path.to_s)
          dependency_paths << path.to_s
        end
      end
  end
end
