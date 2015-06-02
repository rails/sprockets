require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/engines'
require 'sprockets/errors'
require 'sprockets/file_reader'
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
        unless asset = cache.get("asset-uri:#{VERSION}:#{uri}", true)
          id = params.delete(:id)
          uri_without_id = build_asset_uri(filename, params)
          asset = load_asset_by_uri(uri_without_id, filename, params)
          if asset[:id] != id
            @logger.warn "Sprockets load error: Tried to find #{uri}, but latest was id #{asset[:id]}"
          end
        end
      else
        asset = fetch_asset_from_dependency_cache(uri, filename) do |paths|
          if paths
            digest = digest(resolve_dependencies(paths))
            if id_uri = cache.get("asset-uri-digest:#{VERSION}:#{uri}:#{digest}", true)
              cache.get("asset-uri:#{VERSION}:#{id_uri}", true)
            end
          else
            load_asset_by_uri(uri, filename, params)
          end
        end
      end
      Asset.new(self, asset)
    end

    private
      def load_asset_by_uri(uri, filename, params)
        unless file?(filename)
          raise FileNotFound, "could not find file: #{filename}"
        end

        load_path, logical_path = paths_split(config[:paths], filename)

        unless load_path
          raise FileOutsidePaths, "#{filename} is no longer under a load path: #{self.paths.join(', ')}"
        end

        logical_path, file_type, engine_extnames, _ = parse_path_extnames(logical_path)
        name = logical_path

        if pipeline = params[:pipeline]
          logical_path += ".#{pipeline}"
        end

        if type = params[:type]
          logical_path += config[:mime_types][type][:extensions].first
        end

        if type != file_type && !config[:transformers][file_type][type]
          raise ConversionError, "could not convert #{file_type.inspect} to #{type.inspect}"
        end

        processors = processors_for(type, file_type, engine_extnames, pipeline)

        processors_dep_uri = build_processors_uri(type, file_type, engine_extnames, pipeline)
        dependencies = config[:dependencies] + [processors_dep_uri]

        # Read into memory and process if theres a processor pipeline
        if processors.any?
          result = call_processors(processors, {
            environment: self,
            cache: self.cache,
            uri: uri,
            filename: filename,
            load_path: load_path,
            name: name,
            content_type: type,
            metadata: { dependencies: dependencies }
          })
          validate_processor_result!(result)
          source = result.delete(:data)
          metadata = result.merge!(
            charset: source.encoding.name.downcase,
            digest: digest(source),
            length: source.bytesize
          )
        else
          dependencies << build_file_digest_uri(filename)
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
          dependencies_digest: digest(resolve_dependencies(metadata[:dependencies]))
        }

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = build_asset_uri(filename, params.merge(id: asset[:id]))

        # Deprecated: Avoid tracking Asset mtime
        asset[:mtime] = metadata[:dependencies].map { |u|
          if u.start_with?("file-digest:")
            s = self.stat(parse_file_digest_uri(u))
            s ? s.mtime.to_i : nil
          else
            nil
          end
        }.compact.max
        asset[:mtime] ||= self.stat(filename).mtime.to_i

        cache.set("asset-uri:#{VERSION}:#{asset[:uri]}", asset, true)
        cache.set("asset-uri-digest:#{VERSION}:#{uri}:#{asset[:dependencies_digest]}", asset[:uri], true)

        asset
      end

      def fetch_asset_from_dependency_cache(uri, filename, limit = 3)
        key = "asset-uri-cache-dependencies:#{VERSION}:#{uri}:#{file_digest(filename)}"
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
  end
end
