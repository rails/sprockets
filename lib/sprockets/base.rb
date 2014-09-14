require 'sprockets/asset'
require 'sprockets/bower'
require 'sprockets/errors'
require 'sprockets/legacy'
require 'sprockets/resolve'
require 'sprockets/server'
require 'uri'

module Sprockets
  # `Base` class for `Environment` and `Cached`.
  class Base
    include PathUtils, HTTPUtils
    include Configuration
    include Server
    include Resolve
    include Bower
    include Legacy

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

    # Find asset by logical path or expanded path.
    def find_asset(*args)
      status, asset = find_asset_with_status(*args)
      asset if status == :ok
    end

    def build_asset_uri(path, params = {})
      uri = "file://#{URI::Generic::DEFAULT_PARSER.escape(path)}"
      query = []
      query << "type=#{params[:type]}" if params[:type]
      query << "processed" if params[:processed]
      query << "encoding=#{params[:encoding]}" if params[:encoding] && params[:encoding] != 'identity'
      query << "etag=#{params[:etag]}" if params[:etag]
      uri += "?#{query.join('&')}" if query.any?
      uri
    end

    def parse_asset_uri(str)
      uri = URI(str)

      unless uri.scheme == 'file'
        raise InvalidURIError, "expected file:// scheme: #{str}"
      end

      path = URI::Generic::DEFAULT_PARSER.unescape(uri.path)
      path.force_encoding(Encoding::UTF_8)

      params = uri.query.to_s.split('&').reduce({}) do |h, p|
        k, v = p.split('=', 2)
        h.merge(k.to_sym => v || true)
      end

      if params[:type] && !self.mime_types.key?(params[:type])
        raise InvalidURIError, "unknown type: #{params[:type]}"
      end

      if params[:encoding] && !self.encodings.key?(params[:encoding])
        raise InvalidURIError, "unknown encoding: #{params[:encoding]}"
      end

      return path, params
    end

    def update_asset_uri(str, new_params = {})
      path, params = parse_asset_uri(str)
      build_asset_uri(path, params.merge(new_params))
    end

    def find_asset_by_uri(uri)
      _, params = parse_asset_uri(uri)

      if params.key?(:etag)
        Asset.new(self, build_asset_by_etag_uri(uri))
      else
        Asset.new(self, build_asset_by_uri(uri))
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
      def find_asset_with_status(path, options = {})
        path = path.to_s
        options = options.dup
        options[:bundle] = true unless options.key?(:bundle)
        accept = options.delete(:accept)
        if_match = options.delete(:if_match)
        if_none_match = options.delete(:if_none_match)

        if absolute_path?(path)
          path = File.expand_path(path)
          if file?(path) && (accept.nil? || resolve_path_transform_type(path, accept))
            filename = path
          end
        else
          filename = resolve_all(path, accept: accept).first
          mime_type = parse_path_extnames(path)[1]
          accept = parse_accept_options(mime_type, accept).map { |t, v| "#{t}; q=#{v}" }.join(", ")
        end

        if filename
          type = resolve_path_transform_type(filename, accept)

          available_encodings = self.encodings.keys + ['identity']
          encoding = find_best_q_match(options[:accept_encoding], available_encodings)

          uri = build_asset_uri(filename, type: type, processed: !options[:bundle], encoding: encoding)
          asset_hash = build_asset_by_uri(uri)
          asset = Asset.new(self, asset_hash) if asset_hash

          if if_match && asset.digest != if_match
            return :precondition_failed
          elsif if_none_match && asset.digest == if_none_match
            return :not_modified
          else
            return :ok, asset
          end
        else
          return :not_found
        end
      end

      def build_asset_by_etag_uri(uri)
        path, params = parse_asset_uri(uri)

        # Internal assertion, should be routed through build_asset_by_uri
        unless etag = params.delete(:etag)
          raise ArgumentError, "expected uri to have an etag: #{uri}"
        end

        asset = build_asset_by_uri(build_asset_uri(path, params))

        if etag && asset[:digest] != etag
          raise VersionNotFound, "could not find specified etag: #{etag}"
        end

        asset
      end

      def build_asset_by_uri(uri)
        path, params = parse_asset_uri(uri)

        # Internal assertion, should be routed through build_asset_by_etag_uri
        if params.key?(:etag)
          raise ArgumentError, "expected uri to have no etag: #{uri}"
        end

        type     = params[:type]
        encoding = params[:encoding]

        if !file?(path)
          raise FileNotFound, "could not find file: #{path}"
        elsif type && !resolve_path_transform_type(path, type)
          raise ConversionError, "could not convert to type: #{type}"
        end

        build_asset_hash(path, bundle: !params.key?(:processed), type: type, accept_encoding: encoding)
      end

      def build_asset_hash(filename, options)
        load_path, logical_path = paths_split(self.paths, filename)
        unless load_path
          raise FileOutsidePaths, "#{load_path} isn't in paths: #{self.paths.join(', ')}"
        end

        logical_path, file_type, engine_extnames = parse_path_extnames(logical_path)
        logical_path = normalize_logical_path(logical_path)

        asset = {
          load_path: load_path,
          filename: filename,
          name: logical_path
        }

        if asset_type = options[:type]
          asset[:content_type] = asset_type
          asset[:logical_path] = logical_path + mime_types[asset_type][:extensions].first
        else
          asset[:logical_path] = logical_path
        end

        processed_processors = unwrap_preprocessors(file_type) +
          unwrap_engines(engine_extnames).reverse +
          unwrap_transformer(file_type, asset_type) +
          unwrap_postprocessors(asset_type)
        bundled_processors = unwrap_bundle_processors(asset_type)

        should_bundle = options[:bundle] && bundled_processors.any?
        processors = should_bundle ? bundled_processors : processed_processors
        processors += unwrap_encoding_processors(options[:accept_encoding])

        asset[:uri] = build_asset_uri(filename, type: asset[:content_type], processed: processors.any? && !should_bundle)

        if processors.any?
          build_processed_asset_hash(asset, processors)
        else
          build_static_asset_hash(asset)
        end
      end

      def build_processed_asset_hash(asset, processors)
        processed = process(
          processors,
          asset[:uri],
          asset[:filename],
          asset[:load_path],
          asset[:name],
          asset[:content_type],
          read_file(asset[:filename], asset[:content_type])
        )

        # Ensure originally read file is marked as a dependency
        processed[:metadata][:dependency_paths] = Set.new(processed[:metadata][:dependency_paths]).merge([asset[:filename]])

        asset[:uri] = update_asset_uri(asset[:uri], etag: processed[:digest])

        asset.merge(processed).merge({
          mtime: processed[:metadata][:dependency_paths].map { |p| stat(p).mtime.to_i }.max,
          metadata: processed[:metadata].merge(
            dependency_digest: dependencies_hexdigest(processed[:metadata][:dependency_paths])
          )
        })
      end

      def build_static_asset_hash(asset)
        stat   = self.stat(asset[:filename])
        digest = digest_class.file(asset[:filename]).hexdigest
        uri    = update_asset_uri(asset[:uri], etag: digest)

        asset.merge({
          encoding: Encoding::BINARY,
          length: stat.size,
          mtime: stat.mtime.to_i,
          digest: digest,
          uri: uri,
          metadata: {
            dependency_paths: Set.new([asset[:filename]]),
            dependency_digest: dependencies_hexdigest([asset[:filename]]),
          }
        })
      end
  end
end
