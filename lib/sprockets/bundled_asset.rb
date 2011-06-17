require 'sprockets/asset'
require 'sprockets/errors'
require 'fileutils'
require 'set'
require 'time'
require 'zlib'

module Sprockets
  class BundledAsset < Asset
    def self.from_hash(environment, hash)
      asset = allocate
      asset.init_with(environment, hash)
      asset
    end

    def initialize(environment, logical_path, pathname, options)
      @environment  = environment
      @logical_path = logical_path.to_s
      @pathname     = pathname
      @options      = options || {}
    end

    def self.serialized_attributes
      %w( environment_hexdigest
          logical_path pathname
          content_type mtime length digest )
    end

    def init_with(environment, coder)
      @environment = environment
      @options = {}

      self.class.serialized_attributes.each do |attr|
        instance_variable_set("@#{attr}", coder[attr].to_s) if coder[attr]
      end

      @pathname = Pathname.new(@pathname) if @pathname.is_a?(String)
      @mtime    = Time.parse(@mtime)      if @mtime.is_a?(String)
      @length   = Integer(@length)        if @length.is_a?(String)

      @body   = coder['body']
      @source = coder['source']
      @assets = coder['asset_paths'].map { |p| p == pathname.to_s ? self : environment[p, @options] }

      @dependency_files = coder['dependency_files']
      @dependency_files.each do |dep|
        dep['mtime'] = Time.parse(dep['mtime']) if dep['mtime'].is_a?(String)
      end
    end

    def encode_with(coder)
      coder['class'] = 'BundledAsset'

      self.class.serialized_attributes.each do |attr|
        coder[attr] = send(attr).to_s
      end

      coder['body']        = body
      coder['source']      = to_s
      coder['asset_paths'] = to_a.map(&:pathname).map(&:to_s)
      coder['dependency_files'] = dependency_files
    end

    def body
      @body ||= dependency_context_and_body[1]
    end

    def mtime
      @mtime ||= dependency_files.map { |h| h['mtime'] }.max
    end

    def length
      @length ||= Rack::Utils.bytesize(to_s)
    end

    def digest
      @digest ||= environment.digest.update(to_s).hexdigest
    end

    def dependencies?
      dependencies.any?
    end

    def dependencies
      @assets - [self]
    end

    def to_a
      @assets ||= compute_assets
    end

    def each
      yield to_s
    end

    def fresh?
      if environment.digest.hexdigest != environment_hexdigest
        return false
      end

      dependency_files.all? { |h| dependency_fresh?(h) }
    end

    def to_s
      @source ||= build_source
    end

    def write_to(filename, options = {})
      options[:compress] ||= File.extname(filename) == '.gz'

      File.open("#{filename}+", 'wb') do |f|
        if options[:compress]
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.write to_s
          gz.close
        else
          f.write to_s
          f.close
        end
      end

      FileUtils.mv("#{filename}+", filename)
      File.utime(mtime, mtime, filename)

      nil
    ensure
      FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
    end

    protected
      def blank_context
        environment.context_class.new(environment, logical_path.to_s, pathname)
      end

      def dependency_context_and_body
        @dependency_context_and_body ||= build_dependency_context_and_body
      end

      def dependency_context
        dependency_context_and_body[0]
      end

      def dependency_files
        @dependency_files ||= dependency_context._dependency_paths.to_a.map do |path|
          { 'path'      => path,
            'mtime'     => environment.stat(path).mtime,
            'hexdigest' => environment.file_digest(path).hexdigest }
        end
      end

    private
      def check_circular_dependency!
        requires = @options[:_requires] ||= []
        if requires.include?(pathname.to_s)
          raise CircularDependencyError, "#{pathname} has already been required"
        end
        requires << pathname.to_s
      end

      def build_dependency_context_and_body
        context = blank_context
        data = Sprockets::Utils.read_unicode(pathname)
        environment.file_digest(pathname, data)
        body = context.evaluate(pathname, :data => data)
        return context, body
      end

      def build_source
        data = ""
        to_a.each { |dependency| data << dependency.body }
        blank_context.evaluate(pathname, :data => data,
          :processors => environment.bundle_processors(content_type))
      end

      def compute_assets
        check_circular_dependency!

        assets = []

        add_dependency = lambda do |asset|
          unless assets.any? { |a| a.pathname == asset.pathname }
            assets << asset
          end
        end

        dependency_context._required_paths.each do |required_path|
          if required_path == pathname.to_s
            add_dependency.call(self)
          else
            environment[required_path, @options].to_a.each do |asset|
              add_dependency.call(asset)
            end
          end
        end

        add_dependency.call(self)

        assets
      end
  end
end
