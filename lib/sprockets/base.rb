require 'sprockets/asset'
require 'sprockets/bower'
require 'sprockets/errors'
require 'sprockets/resolve'
require 'sprockets/server'
require 'pathname'

module Sprockets
  # `Base` class for `Environment` and `Cached`.
  class Base
    include PathUtils, HTTPUtils
    include Configuration
    include Server
    include Resolve
    include Bower

    # Get persistent cache store
    attr_reader :cache

    # Set persistent cache store
    #
    # The cache store must implement a pair of getters and
    # setters. Either `get(key)`/`set(key, value)`,
    # `[key]`/`[key]=value`, `read(key)`/`write(key, value)`.
    def cache=(cache)
      @cache = Cache.new(cache, logger)
    end

    # Return an `Cached`. Must be implemented by the subclass.
    def cached
      raise NotImplementedError
    end
    alias_method :index, :cached

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

    # Experimental: Check if environment has asset.
    #
    # Acts similar to `find_asset(path) ? true : false` but does not build the
    # entire asset.
    #
    # Returns true or false.
    def has_asset?(filename, options = {})
      return false unless file?(filename)

      accepts = options[:accept] || '*/*'

      extname = parse_path_extnames(filename)[1]
      if mime_type = mime_exts[extname]
        accepts = parse_q_values(accepts)
        accepts.any? { |accept, q| match_mime_type?(mime_type, accept) }
      else
        accepts == '*/*'
      end
    end

    # Find asset by logical path or expanded path.
    def find_asset(path, options = {})
      path = path.to_s
      options = options.dup
      options[:bundle] = true unless options.key?(:bundle)
      accept = options.delete(:accept)
      if_match = options.delete(:if_match)

      if absolute_path?(path) && has_asset?(path, accept: accept)
        filename = path
        return nil unless file?(filename)
      else
        filename = resolve_all(path, accept: accept).first
      end

      if filename
        options = { bundle: options[:bundle], accept_encoding: options[:accept_encoding] }
        if if_match
          asset_hash = build_asset_hash_for_digest(filename, if_match, options)
        else
          asset_hash = build_asset_hash(filename, options)
        end

        Asset.new(asset_hash) if asset_hash
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
        "paths=#{paths.inspect}>"
    end

    protected
      def build_asset_hash_for_digest(filename, digest, options)
        asset_hash = build_asset_hash(filename, options)
        if asset_hash[:digest] == digest
          asset_hash
        end
      end

      def build_asset_hash(filename, options)
        load_path, logical_path = paths_split(self.paths, filename)
        unless load_path
          raise FileOutsidePaths, "#{load_path} isn't in paths: #{self.paths.join(', ')}"
        end

        logical_path, extname, engine_extnames = parse_path_extnames(logical_path)
        logical_path = normalize_logical_path(logical_path)
        logical_path += extname if extname
        mime_type = mime_exts[extname]

        asset = {
          load_path: load_path,
          filename: filename,
          logical_path: logical_path,
          name: logical_path.chomp(extname)
        }
        asset[:content_type] = mime_type if mime_type

        processed_processors = unwrap_preprocessors(asset[:content_type]) +
          unwrap_engines(engine_extnames).reverse +
          unwrap_postprocessors(asset[:content_type])
        bundled_processors = unwrap_bundle_processors(asset[:content_type])

        bundle_supported = options[:bundle] && bundled_processors.include?(Bundle)
        processors = bundle_supported ? bundled_processors : processed_processors
        processors += unwrap_encoding_processors(options[:accept_encoding])

        if processors.any?
          build_processed_asset_hash(asset, processors)
        else
          build_static_asset_hash(asset)
        end
      end

      def build_processed_asset_hash(asset, processors)
        filename = asset[:filename]

        data = File.open(filename, 'rb') { |f| f.read }

        content_type = asset[:content_type]
        mime_type = mime_types[content_type]
        if mime_type && mime_type[:charset]
          data = mime_type[:charset].call(data).encode(Encoding::UTF_8)
        end

        processed = process(
          processors,
          filename,
          asset[:load_path],
          asset[:name],
          content_type,
          data
        )

        # Ensure originally read file is marked as a dependency
        processed[:metadata][:dependency_paths] = Set.new(processed[:metadata][:dependency_paths]).merge([filename])

        asset.merge(processed).merge({
          mtime: processed[:metadata][:dependency_paths].map { |path| stat(path).mtime.to_i }.max,
          metadata: processed[:metadata].merge(
            dependency_digest: dependencies_hexdigest(processed[:metadata][:dependency_paths])
          )
        })
      end

      def build_static_asset_hash(asset)
        stat = self.stat(asset[:filename])
        asset.merge({
          encoding: Encoding::BINARY,
          length: stat.size,
          mtime: stat.mtime.to_i,
          digest: digest_class.file(asset[:filename]).hexdigest,
          metadata: {
            dependency_paths: Set.new([asset[:filename]]),
            dependency_digest: dependencies_hexdigest([asset[:filename]]),
          }
        })
      end
  end
end
