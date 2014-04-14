require 'sprockets/asset_attributes'
require 'sprockets/bower'
require 'sprockets/bundled_asset'
require 'sprockets/errors'
require 'sprockets/processed_asset'
require 'sprockets/server'
require 'sprockets/static_asset'
require 'json'
require 'pathname'

module Sprockets
  # `Base` class for `Environment` and `Index`.
  class Base
    include Paths, Bower, Mime, Processing, Compressing, Engines, Server

    # Returns a `Digest` implementation class.
    #
    # Defaults to `Digest::SHA1`.
    attr_reader :digest_class

    # Assign a `Digest` implementation class. This maybe any Ruby
    # `Digest::` implementation such as `Digest::SHA1` or
    # `Digest::MD5`.
    #
    #     environment.digest_class = Digest::MD5
    #
    def digest_class=(klass)
      expire_index!
      @digest_class = klass
    end

    # The `Environment#version` is a custom value used for manually
    # expiring all asset caches.
    #
    # Sprockets is able to track most file and directory changes and
    # will take care of expiring the cache for you. However, its
    # impossible to know when any custom helpers change that you mix
    # into the `Context`.
    #
    # It would be wise to increment this value anytime you make a
    # configuration change to the `Environment` object.
    attr_reader :version

    # Assign an environment version.
    #
    #     environment.version = '2.0'
    #
    def version=(version)
      expire_index!
      @version = version
    end

    # Returns a `Digest` instance for the `Environment`.
    #
    # This value serves two purposes. If two `Environment`s have the
    # same digest value they can be treated as equal. This is more
    # useful for comparing environment states between processes rather
    # than in the same. Two equal `Environment`s can share the same
    # cached assets.
    #
    # The value also provides a seed digest for all `Asset`
    # digests. Any change in the environment digest will affect all of
    # its assets.
    def digest
      # Compute the initial digest using the implementation class. The
      # Sprockets release version and custom environment version are
      # mixed in. So any new releases will affect all your assets.
      @digest ||= digest_class.new.update(VERSION).update(version.to_s)

      # Returned a dupped copy so the caller can safely mutate it with `.update`
      @digest.dup
    end

    # Get and set `Logger` instance.
    attr_accessor :logger

    # Get `Context` class.
    #
    # This class maybe mutated and mixed in with custom helpers.
    #
    #     environment.context_class.instance_eval do
    #       include MyHelpers
    #       def asset_url; end
    #     end
    #
    attr_reader :context_class

    # Get persistent cache store
    attr_reader :cache

    # Set persistent cache store
    #
    # The cache store must implement a pair of getters and
    # setters. Either `get(key)`/`set(key, value)`,
    # `[key]`/`[key]=value`, `read(key)`/`write(key, value)`.
    def cache=(cache)
      expire_index!
      @cache = Cache.new(cache)
    end

    def prepend_path(path)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def append_path(path)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def clear_paths
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    # Internal: Reverse guess logical path for fully expanded path.
    #
    # This has some known issues. For an example if a file is
    # shaddowed in the path, but is required relatively, its logical
    # path will be incorrect.
    def logical_path_for(filename)
      if root_path = paths.detect { |path| filename[path] }
        path = Pathname.new(filename).relative_path_from(Pathname.new(root_path)).to_s
        attributes = attributes_for(filename)
        path = attributes.engine_extensions.inject(path) { |p, ext| p.sub(ext, '') }
        path = "#{path}#{attributes.send(:engine_format_extension)}" unless attributes.format_extension
        path
      else
        raise FileOutsidePaths, "#{filename} isn't in paths: #{paths.join(', ')}"
      end
    end

    # Finds the expanded real path for a given logical path by
    # searching the environment's paths.
    #
    #     resolve("application.js")
    #     # => "/path/to/app/javascripts/application.js.coffee"
    #
    # A `FileNotFound` exception is raised if the file does not exist.
    def resolve(path, options = {})
      if Pathname.new(path).absolute?
        unless paths.detect { |root| path[root] }
          raise FileOutsidePaths, "#{path} isn't in paths: #{paths.join(', ')}"
        end
      end

      if filename = resolve_all(path, options).first
        filename
      else
        content_type = options[:content_type]
        message = "couldn't find file '#{path}'"
        message << " with content type '#{content_type}'" if content_type
        raise FileNotFound, message
      end
    end

    # Register a new mime type.
    def register_mime_type(mime_type, ext)
      # Overrides the global behavior to expire the index
      expire_index!
      @trail.append_extension(ext)
      super
    end

    # Registers a new Engine `klass` for `ext`.
    def register_engine(ext, klass, options = {})
      # Overrides the global behavior to expire the index
      expire_index!
      super
      add_engine_to_trail(ext)
    end

    def register_preprocessor(mime_type, klass, &block)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def unregister_preprocessor(mime_type, klass)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def register_postprocessor(mime_type, klass, &block)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def unregister_postprocessor(mime_type, klass)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def register_bundle_processor(mime_type, klass, &block)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    def unregister_bundle_processor(mime_type, klass)
      # Overrides the global behavior to expire the index
      expire_index!
      super
    end

    # Return an `Index`. Must be implemented by the subclass.
    def index
      raise NotImplementedError
    end

    # Define `default_external_encoding` accessor on 1.9.
    # Defaults to UTF-8.
    attr_accessor :default_external_encoding

    # Internal: Compute hexdigest for path.
    #
    # path - String filename or directory path.
    #
    # Returns a String SHA1 hexdigest or nil.
    def file_hexdigest(path)
      if stat = self.stat(path)
        # Caveat: Digests are cached by the path's current mtime. Its possible
        # for a files contents to have changed and its mtime to have been
        # negligently reset thus appearing as if the file hasn't changed on
        # disk. Also, the mtime is only read to the nearest second. Its
        # also possible the file was updated more than once in a given second.
        cache.fetch("hexdigest:#{path}:#{stat.mtime.to_i}") do
          if stat.directory?
            # If its a directive, digest the list of filenames
            Digest::SHA1.hexdigest(self.entries(path).join(','))
          elsif stat.file?
            # If its a file, digest the contents
            Digest::SHA1.file(path.to_s).hexdigest
          end
        end
      end
    end

    # Internal: Compute hexdigest for a set of paths.
    #
    # paths - Array of filename or directory paths.
    #
    # Returns a String SHA1 hexdigest.
    def dependencies_hexdigest(paths)
      digest = Digest::SHA1.new
      paths.each { |path| digest.update(file_hexdigest(path).to_s) }
      digest.hexdigest
    end

    # Internal. Return a `AssetAttributes` for `path`.
    def attributes_for(path)
      AssetAttributes.new(self, path)
    end

    # Internal. Return content type of `path`.
    def content_type_of(path)
      attributes_for(path).content_type
    end

    # Find asset by logical path or expanded path.
    # def find_asset(path, options = {})
    # end

    # Preferred `find_asset` shorthand.
    #
    #     environment['application.js']
    #
    def [](*args)
      find_asset(*args)
    end

    # Pretty inspect
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} " +
        "root=#{root.to_s.inspect}, " +
        "paths=#{paths.inspect}, " +
        "digest=#{digest.to_s.inspect}" +
        ">"
    end

    protected
      # Clear index after mutating state. Must be implemented by the subclass.
      def expire_index!
        raise NotImplementedError
      end

      def build_asset(filename, options)
        logical_path = logical_path_for(filename)

        # If there are any processors to run on the pathname, use
        # `BundledAsset`. Otherwise use `StaticAsset` and treat is as binary.
        if attributes_for(filename).processors.any?
          if options[:bundle] == false
            circular_call_protection(filename) do
              ProcessedAsset.new(index, logical_path, filename)
            end
          else
            BundledAsset.new(index, logical_path, filename)
          end
        else
          StaticAsset.new(index, logical_path, filename)
        end
      end

      def asset_cache_key_for(path, options)
        "#{digest.hexdigest}/asset/#{path}:#{options[:bundle] ? '1' : '0'}"
      end

      def circular_call_protection(path)
        reset = Thread.current[:sprockets_circular_calls].nil?
        calls = Thread.current[:sprockets_circular_calls] ||= Set.new
        if calls.include?(path)
          raise CircularDependencyError, "#{path} has already been required"
        end
        calls << path
        yield
      ensure
        Thread.current[:sprockets_circular_calls] = nil if reset
      end
  end
end
