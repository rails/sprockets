require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/engines'
require 'sprockets/errors'
require 'sprockets/mime'
require 'sprockets/path_utils'
require 'sprockets/processing'
require 'sprockets/resolve'
require 'sprockets/transformers'
require 'sprockets/uri_utils'

module Sprockets
  # The loader phase takes a asset URI location and returns a constructed Asset
  # object.
  module Loader
    include DigestUtils, Engines, Mime, PathUtils, URIUtils, Processing, Resolve, Transformers

    # Public: Load Asset by AssetURI.
    #
    # uri - AssetURI
    #
    # Returns Asset.
    def load(uri)
      _, params = parse_asset_uri(uri)
      if params.key?(:id)
        asset = cache.fetch(asset_uri_cache_key(uri)) do
          load_asset_by_id_uri(uri)
        end
      else
        asset = fetch_asset_from_dependency_cache(uri) do |paths|
          if paths
            if id_uri = cache.__get(asset_digest_cache_key(uri, files_digest(paths)))
              cache.__get(asset_uri_cache_key(id_uri))
            end
          else
            load_asset_by_uri(uri)
          end
        end
      end
      Asset.new(asset)
    end

    private
      def asset_digest_cache_key(uri, digest)
        [
          'asset-uri-digest',
          VERSION,
          self.version,
          self.paths,
          uri,
          digest
        ]
      end

      def asset_cache_dependencies_key(uri)
        filename, _ = parse_asset_uri(uri)
        [
          'asset-uri-cache-dependencies',
          VERSION,
          self.version,
          self.paths,
          uri,
          file_digest(filename)
        ]
      end

      def asset_uri_cache_key(uri)
        [
          'asset-uri',
          VERSION,
          self.version,
          uri
        ]
      end

      def load_asset_by_id_uri(uri)
        path, params = parse_asset_uri(uri)

        # Internal assertion, should be routed through load_asset_by_uri
        unless id = params.delete(:id)
          raise ArgumentError, "expected uri to have an id: #{uri}"
        end

        asset = load_asset_by_uri(build_asset_uri(path, params))

        if id && asset[:id] != id
          raise VersionNotFound, "could not find specified id: #{id}"
        end

        asset
      end

      def load_asset_by_uri(uri)
        filename, params = parse_asset_uri(uri)

        # Internal assertion, should be routed through load_asset_by_id_uri
        if params.key?(:id)
          raise ArgumentError, "expected uri to have no id: #{uri}"
        end

        unless file?(filename)
          raise FileNotFound, "could not find file: #{filename}"
        end

        load_path, logical_path = paths_split(self.paths, filename)

        unless load_path
          raise FileOutsidePaths, "#{filename} is no longer under a load path: #{self.paths.join(', ')}"
        end

        logical_path, file_type, engine_extnames = parse_path_extnames(logical_path)
        logical_path = normalize_logical_path(logical_path)

        asset = {
          uri: uri,
          load_path: load_path,
          filename: filename,
          name: logical_path,
          logical_path: logical_path
        }

        if type = params[:type]
          asset[:content_type] = type
          asset[:logical_path] += mime_types[type][:extensions].first
        end

        processors = processors_for(file_type, engine_extnames, params)

        # Read into memory and process if theres a processor pipeline or the
        # content type is text.
        if processors.any? || mime_type_charset_detecter(type)
          data = read_file(asset[:filename], asset[:content_type])
          metadata = {}

          input = {
            environment: self,
            cache: self.cache,
            uri: asset[:uri],
            filename: asset[:filename],
            load_path: asset[:load_path],
            name: asset[:name],
            content_type: asset[:content_type],
            map: SourceMap::Map.new,
            metadata: metadata
          }

          processors.each do |processor|
            begin
              result = processor.call(input.merge(data: data, metadata: metadata))
              case result
              when NilClass
                # noop
              when Hash
                data = result[:data] if result.key?(:data)
                metadata = metadata.merge(result)
                metadata.delete(:data)
              when String
                data = result
              else
                raise Error, "invalid processor return type: #{result.class}"
              end
            end
          end

          asset[:source] = data
          asset[:metadata] = metadata.merge(
            charset: data.encoding.name.downcase,
            digest: digest(data),
            length: data.bytesize
          )
        else
          asset[:metadata] = {
            digest: file_digest(asset[:filename]),
            length: self.stat(asset[:filename]).size
          }
        end

        metadata = asset[:metadata]
        metadata[:dependency_paths] = Set.new(metadata[:dependency_paths]).merge([asset[:filename]])
        metadata[:dependency_sources_digest] = files_digest(metadata[:dependency_paths])

        asset[:integrity] = integrity_uri(asset[:metadata][:digest], asset[:content_type])

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = build_asset_uri(filename, params.merge(id: asset[:id]))

        cache.__set(asset_uri_cache_key(asset[:uri]), asset)
        cache.__set(asset_digest_cache_key(uri, asset[:metadata][:dependency_sources_digest]), asset[:uri])

        asset
      end

      def fetch_asset_from_dependency_cache(uri, limit = 3)
        key = asset_cache_dependencies_key(uri)
        history = cache._get(key) || []

        history.each_with_index do |deps, index|
          if asset = yield(deps)
            cache._set(key, history.rotate!(index)) if index > 0
            return asset
          end
        end

        asset = yield
        deps = asset[:metadata][:dependency_paths]
        cache._set(key, history.unshift(deps).take(limit))
        asset
      end

      def processors_for(file_type, engine_extnames, params)
        type = params[:type]

        if type != file_type
          transformers = unwrap_transformer(file_type, type)
          unless transformers.any?
            raise ConversionError, "could not convert #{file_type.inspect} to #{type.inspect}"
          end
        else
          transformers = []
        end

        processed_processors = unwrap_preprocessors(file_type) +
          unwrap_engines(engine_extnames).reverse +
          transformers +
          unwrap_postprocessors(type)

        bundled_processors = params[:skip_bundle] ? [] : unwrap_bundle_processors(type)

        processors = bundled_processors.any? ? bundled_processors : processed_processors
        processors += unwrap_encoding_processors(params[:encoding])
      end
  end
end
