require 'sprockets/bower'
require 'sprockets/bundled_asset'
require 'sprockets/errors'
require 'sprockets/processed_asset'
require 'sprockets/server'
require 'sprockets/static_asset'
require 'pathname'

module Sprockets
  # `Base` class for `Environment` and `Cached`.
  class Base
    include PathUtils
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
      expire_cache!
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
      expire_cache!
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
      expire_cache!
      @cache = Cache.new(cache, logger)
    end

    def prepend_path(path)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def append_path(path)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def clear_paths
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    # Finds the expanded real path for a given logical path by
    # searching the environment's paths.
    #
    #     resolve("application.js")
    #     # => "/path/to/app/javascripts/application.js.coffee"
    #
    # A `FileNotFound` exception is raised if the file does not exist.
    def resolve(path, options = {})
      if absolute_path?(path.to_s)
        unless paths_split(self.paths, path)
          raise FileOutsidePaths, "#{path} isn't in paths: #{self.paths.join(', ')}"
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
      # Overrides the global behavior to expire the cache
      expire_cache!
      @trail.append_extension(ext)
      super
    end

    # Registers a new Engine `klass` for `ext`.
    def register_engine(ext, klass, options = {})
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
      add_engine_to_trail(ext.to_s)
    end

    def register_preprocessor(mime_type, klass, &block)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def unregister_preprocessor(mime_type, klass)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def register_postprocessor(mime_type, klass, &block)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def unregister_postprocessor(mime_type, klass)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def register_bundle_processor(mime_type, klass, &block)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    def unregister_bundle_processor(mime_type, klass)
      # Overrides the global behavior to expire the cache
      expire_cache!
      super
    end

    # Return an `Cached`. Must be implemented by the subclass.
    def cached
      raise NotImplementedError
    end
    alias_method :index, :cached

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
        cache.fetch(['file_hexdigest', path, stat.mtime.to_i]) do
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

    # Find asset by logical path or expanded path.
    def find_asset(path, options = {})
      options[:bundle] = true unless options.key?(:bundle)

      if filename = resolve_all(path.to_s).first
        asset_hash = build_asset_hash(filename, options[:bundle])

        case asset_hash[:type]
        when 'bundled'
          BundledAsset.new(asset_hash)
        when 'processed'
          ProcessedAsset.new(asset_hash)
        when 'static'
          StaticAsset.new(asset_hash)
        end
      end
    end

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
      # Clear cached environment after mutating state. Must be implemented by
      # the subclass.
      def expire_cache!
        raise NotImplementedError
      end

      def build_asset_hash(filename, bundle = true)
        unless self.stat(filename)
          # FIXME: Shouldn't need this check.
          raise FileNotFound, "could not find #{filename}"
        end

        content_type = content_type_of(filename)

        attributes = {
          filename: filename,
          logical_path: logical_path_for(filename),
          content_type: content_type
        }

        engine_exts = engine_extensions_for(filename)
        processed_processors = preprocessors(content_type) +
          engine_exts.map { |ext| engines(ext) }.reverse +
          postprocessors(content_type)
        bundled_processors = bundle_processors(content_type)

        # If there are any processors to run on the pathname, use
        # `BundledAsset`. Otherwise use `StaticAsset` and treat is as binary.
        if processed_processors.any? || bundled_processors.any?
          if bundle == false
            benchmark "Compiled #{attributes[:logical_path]}" do
              build_processed_asset_hash(attributes, processed_processors)
            end
          else
            Utils.prevent_circular_calls(filename) do
              build_bundled_asset_hash(attributes, bundled_processors)
            end
          end
        else
          build_static_asset_hash(attributes)
        end
      end

      def build_processed_asset_hash(asset, processors)
        filename  = asset[:filename]
        encoding  = encoding_for_mime_type(asset[:content_type])
        data      = read_unicode_file(filename, encoding)
        processed = process(processors, filename, data)

        asset.merge(processed).merge(
          type: 'processed',
          dependency_digest: dependencies_hexdigest(processed[:dependency_paths]),
          mtime: processed[:dependency_paths].map { |path| stat(path).mtime }.max.to_i
        )
      end

      def build_bundled_asset_hash(asset, processors)
        processed_asset = build_asset_hash(asset[:filename], false)

        bundled_assets = {}

        required_paths = Set.new
        processed_asset[:required_paths].each do |path|
          if path == asset[:filename]
            required_paths << path
          else
            asset_hash = bundled_assets[path] ||= build_asset_hash(path, true)
            required_paths.merge(asset_hash[:required_paths])
          end
        end

        processed_asset[:stubbed_paths].each do |path|
          asset_hash = bundled_assets[path] ||= build_asset_hash(path, true)
          required_paths.subtract(asset_hash[:required_paths])
        end

        dependency_paths = Set.new
        required_asset_hashes = required_paths.map do |filename|
          asset_hash = build_asset_hash(filename, false)
          dependency_paths.merge(asset_hash[:dependency_paths])
          asset_hash
        end

        asset.merge(process(
          processors,
          asset[:filename],
          required_asset_hashes.map { |h| h[:source] }.join
        )).merge({
          type: 'bundled',
          required_paths: required_paths.to_a,
          required_asset_hashes: required_asset_hashes,
          dependency_paths: dependency_paths.to_a,
          dependency_digest: dependencies_hexdigest(dependency_paths),
          mtime: required_asset_hashes.map { |h| h[:mtime] }.max
        })
      end

      def build_static_asset_hash(asset)
        stat = self.stat(asset[:filename])
        asset.merge({
          type: 'static',
          length: stat.size,
          mtime: stat.mtime.to_i,
          digest: digest.file(asset[:filename]).hexdigest,
          dependency_digest: dependencies_hexdigest([asset[:filename]]),
          dependency_paths: [asset[:filename]]
        })
      end

      def benchmark(message)
        start_time = Time.now.to_f
        result = yield
        elapsed_time = ((Time.now.to_f - start_time) * 1000).to_i
        logger.debug "#{message}  (#{elapsed_time}ms)  (pid #{Process.pid})"
        result
      end
  end
end
