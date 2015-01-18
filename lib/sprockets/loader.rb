require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/engines'
require 'sprockets/errors'
require 'sprockets/mime'
require 'sprockets/path_utils'
require 'sprockets/processing'
require 'sprockets/processor_utils'
require 'sprockets/resolve'
require 'sprockets/transformers'
require 'sprockets/uri_utils'

module Sprockets
  # The loader phase takes a asset URI location and returns a constructed Asset
  # object.
  module Loader
    include DigestUtils, PathUtils, ProcessorUtils, URIUtils
    include Engines, Mime, Processing, Resolve, Transformers

    # Public: Load Asset by AssetURI.
    #
    # uri - AssetURI
    #
    # Returns Asset.
    def load(uri)
      filename, params = parse_asset_uri(uri)
      if params.key?(:id)
        key = ['asset-uri', uri]
        asset = cache.fetch(key) do
          load_asset_by_id_uri(uri, filename, params)
        end
      else
        asset = fetch_asset_from_dependency_cache(uri, filename) do |paths|
          if paths
            digest = resolve_cache_dependencies(paths)
            key = ['asset-uri-digest', uri, digest]
            if id_uri = cache.__get(key)
              key = ['asset-uri', id_uri]
              cache.__get(key)
            end
          else
            load_asset_by_uri(uri, filename, params)
          end
        end
      end
      Asset.new(self, asset)
    end

    private
      def load_asset_by_id_uri(uri, filename, params)
        # Internal assertion, should be routed through load_asset_by_uri
        unless id = params.delete(:id)
          raise ArgumentError, "expected uri to have an id: #{uri}"
        end

        uri = build_asset_uri(filename, params)
        asset = load_asset_by_uri(uri, filename, params)

        if id && asset[:id] != id
          raise VersionNotFound, "could not find specified id: #{id}"
        end

        asset
      end

      def load_asset_by_uri(uri, filename, params)
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
          input = {
            environment: self,
            cache: self.cache,
            uri: asset[:uri],
            filename: asset[:filename],
            load_path: asset[:load_path],
            name: asset[:name],
            content_type: asset[:content_type],
            data: read_file(asset[:filename], asset[:content_type]),
            metadata: {}
          }
          result = call_processors(processors, input)
          data = asset[:source] = result.delete(:data)
          asset[:metadata] = result.merge(
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
        metadata[:cache_dependencies] = cache_dependencies.dup
          .merge(metadata[:cache_dependencies] || [])
          .merge([URIUtils.build_file_digest_uri(asset[:filename])])

        metadata[:cache_dependencies_digest] = resolve_cache_dependencies(metadata[:cache_dependencies])

        asset[:integrity] = integrity_uri(asset[:metadata][:digest], asset[:content_type])

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = build_asset_uri(filename, params.merge(id: asset[:id]))

        # Deprecated: Avoid tracking Asset mtime
        asset[:mtime] = metadata[:cache_dependencies].map { |u|
          u.start_with?("file-digest:") ?
            stat(parse_file_digest_uri(u)).mtime.to_i :
            0
        }.max

        key = ['asset-uri', asset[:uri]]
        cache.__set(key, asset)

        key = ['asset-uri-digest', uri, asset[:metadata][:cache_dependencies_digest]]
        cache.__set(key, asset[:uri])

        asset
      end

      def fetch_asset_from_dependency_cache(uri, filename, limit = 3)
        key = ['asset-uri-cache-dependencies', uri, file_digest(filename)]
        history = cache._get(key) || []

        history.each_with_index do |deps, index|
          if asset = yield(deps)
            cache._set(key, history.rotate!(index)) if index > 0
            return asset
          end
        end

        asset = yield
        deps = asset[:metadata][:cache_dependencies]
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
        processors.reverse
      end
  end
end
