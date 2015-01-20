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
        asset = cache.fetch(['asset-uri', uri]) do
          load_asset_by_id_uri(uri, filename, params)
        end
      else
        asset = fetch_asset_from_dependency_cache(uri, filename) do |paths|
          if paths
            digest = digest(resolve_dependencies(paths))
            if id_uri = cache.get(['asset-uri-digest', uri, digest], true)
              cache.get(['asset-uri', id_uri], true)
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
        name = logical_path

        if type = params[:type]
          logical_path += mime_types[type][:extensions].first
        end

        processors = processors_for(file_type, engine_extnames, params)

        processor_dependencies = Set.new(processors.map { |processor|
          config[:inverted_processor_dependency_uris][processor]
        }.compact)

        processors = unwrap_processors(processors)

        dependencies = self.dependencies
        dependencies += Set.new([build_file_digest_uri(filename)])
        dependencies += processor_dependencies

        # Read into memory and process if theres a processor pipeline or the
        # content type is text.
        if processors.any? || mime_type_charset_detecter(type)
          result = call_processors(processors, {
            environment: self,
            cache: self.cache,
            uri: uri,
            filename: filename,
            load_path: load_path,
            name: name,
            content_type: type,
            data: read_file(filename, type),
            metadata: { dependencies: dependencies }
          })
          source = result.delete(:data)
          metadata = result.merge!(
            charset: source.encoding.name.downcase,
            digest: digest(source),
            length: source.bytesize
          )
        else
          metadata = {
            digest: file_digest(filename),
            length: self.stat(filename).size,
            dependencies: dependencies
          }
        end

        asset = {
          uri: uri,
          load_path: load_path,
          filename: filename,
          name: name,
          logical_path: logical_path,
          content_type: type,
          source: source,
          metadata: metadata,
          integrity: integrity_uri(metadata[:digest], type),
          dependencies_digest: digest(resolve_dependencies(metadata[:dependencies]))
        }

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = build_asset_uri(filename, params.merge(id: asset[:id]))

        # Deprecated: Avoid tracking Asset mtime
        asset[:mtime] = metadata[:dependencies].map { |u|
          u.start_with?("file-digest:") ?
            stat(parse_file_digest_uri(u)).mtime.to_i :
            0
        }.max

        cache.set(['asset-uri', asset[:uri]], asset, true)
        cache.set(['asset-uri-digest', uri, asset[:dependencies_digest]], asset[:uri], true)

        asset
      end

      def fetch_asset_from_dependency_cache(uri, filename, limit = 3)
        key = ['asset-uri-cache-dependencies', uri, file_digest(filename)]
        history = cache.get(key) || []

        history.each_with_index do |deps, index|
          if asset = yield(deps)
            cache.set(key, history.rotate!(index)) if index > 0
            return asset
          end
        end

        asset = yield
        deps = asset[:metadata][:dependencies]
        cache.set(key, history.unshift(deps).take(limit))
        asset
      end

      def processors_for(file_type, engine_extnames, params)
        type = params[:type]

        processors = []

        if processor = encoding_processor_for(params[:encoding])
          processors += [processor]
        end

        bundled_processors = params[:skip_bundle] ? [] : config[:bundle_processors][type]

        if bundled_processors.any?
          processors += bundled_processors
        else
          processors += config[:postprocessors][type]

          if type != file_type
            if processor = transformers[file_type][type]
              processors += [processor]
            else
              raise ConversionError, "could not convert #{file_type.inspect} to #{type.inspect}"
            end
          end

          processors += engine_extnames.map { |ext| engines[ext] }
          processors += config[:preprocessors][file_type]
        end

        processors
      end
  end
end
