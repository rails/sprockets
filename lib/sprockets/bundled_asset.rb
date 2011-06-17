require 'sprockets/dependency'
require 'sprockets/errors'
require 'fileutils'
require 'set'
require 'time'
require 'zlib'

module Sprockets
  class BundledAsset
    attr_reader :environment
    attr_reader :logical_path, :pathname, :mtime, :body

    def self.from_hash(environment, hash)
      asset = allocate
      asset.init_with(environment, hash)
      asset
    end

    def initialize(environment, logical_path, pathname, options)
      @environment = environment

      @logical_path = logical_path.to_s
      @pathname     = pathname

      @assets = []
      @source = nil

      data  = Sprockets::Utils.read_unicode(pathname)
      @body = context.evaluate(pathname, :data => data)
      environment.file_digest(pathname, data)

      requires = options[:_requires] ||= []
      if requires.include?(pathname.to_s)
        raise CircularDependencyError, "#{pathname} has already been required"
      end
      requires << pathname.to_s

      compute_dependencies!(environment, options)
      compute_dependency_files!
    end

    def self.serialized_attributes
      %w( environment_hexdigest
          logical_path pathname
          content_type mtime length digest )
    end

    def init_with(environment, coder)
      @environment = environment
      options = {}

      self.class.serialized_attributes.each do |attr|
        instance_variable_set("@#{attr}", coder[attr].to_s) if coder[attr]
      end

      @pathname = Pathname.new(@pathname) if @pathname.is_a?(String)
      @mtime    = Time.parse(@mtime)      if @mtime.is_a?(String)
      @length   = Integer(@length)        if @length.is_a?(String)

      @body   = coder['body']
      @source = coder['source']
      @assets = coder['asset_paths'].map { |p| p == pathname.to_s ? self : environment[p, options] }

      @dependency_files = coder['dependency_files'].inject({}) { |h, hash|
        dep = Dependency.from_hash(hash)
        h[dep.path] = dep
        h
      }
    end

    def encode_with(coder)
      coder['class'] = 'BundledAsset'

      self.class.serialized_attributes.each do |attr|
        coder[attr] = send(attr).to_s
      end

      coder['body']        = body
      coder['source']      = source
      coder['asset_paths'] = to_a.map(&:pathname).map(&:to_s)
      coder['dependency_files'] = dependency_files.values.map { |dep| h = {}; dep.encode_with(h); h }
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

    def fresh?
      if environment.digest.hexdigest != environment_hexdigest
        return false
      end

      dependency_files.values.all? { |dep| dep.fresh?(environment) }
    end

    def stale?
      !fresh?
    end

    def to_s
      source
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "pathname=#{pathname.to_s.inspect}, " +
        "mtime=#{mtime.inspect}, " +
        "digest=#{digest.inspect}" +
        ">"
    end

    def write_to(filename, options = {})
      options[:compress] ||= File.extname(filename) == '.gz'

      File.open("#{filename}+", 'wb') do |f|
        if options[:compress]
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.write source
          gz.close
        else
          f.write(source)
          f.close
        end
      end

      FileUtils.mv("#{filename}+", filename)
      File.utime(mtime, mtime, filename)

      nil
    ensure
      FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
    end

    def eql?(other)
      other.class == self.class &&
        other.pathname == self.pathname &&
        other.mtime == self.mtime &&
        other.digest == self.digest
    end
    alias_method :==, :eql?

    protected
      attr_reader :dependency_files

      def environment_hexdigest
        @environment_hexdigest ||= environment.digest.hexdigest
      end

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

      Epoch = Time.at(0)

      def compute_dependency_files!
        @dependency_files = {}
        @mtime = Epoch

        depend_on(pathname)

        context._dependency_paths.each do |path|
          depend_on(path)
        end

        to_a.each do |dependency|
          dependency.dependency_files.each do |path, dep|
            depend_on(path, dep)
          end
        end
      end

      def depend_on(path, dep = nil)
        dep = dependency_files[path.to_s] ||= (dep || Dependency.from_path(environment, path))

        if dep.mtime > @mtime
          @mtime = dep.mtime
        end
      end
  end
end
