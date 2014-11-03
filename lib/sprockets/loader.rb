require 'sprockets/asset_uri'
require 'sprockets/asset'
require 'sprockets/digest_utils'
require 'sprockets/engines'
require 'sprockets/errors'
require 'sprockets/mime'
require 'sprockets/path_utils'
require 'sprockets/processing'
require 'sprockets/resolve'
require 'sprockets/transformers'

module Sprockets
  # The loader phase takes a asset URI location and returns a constructed Asset
  # object.
  module Loader
    include DigestUtils, Engines, Mime, PathUtils, Processing, Resolve, Transformers

    # Public: Load Asset by AssetURI.
    #
    # uri - AssetURI
    #
    # Returns Asset.
    def load(uri)
      _, params = AssetURI.parse(uri)
      asset = params.key?(:id) ?
        load_asset_by_id_uri(uri) :
        load_asset_by_uri(uri)
      Asset.new(self, asset)
    end

    private
      def load_asset_by_id_uri(uri)
        path, params = AssetURI.parse(uri)

        # Internal assertion, should be routed through load_asset_by_uri
        unless id = params.delete(:id)
          raise ArgumentError, "expected uri to have an id: #{uri}"
        end

        asset = load_asset_by_uri(AssetURI.build(path, params))

        if id && asset[:id] != id
          raise VersionNotFound, "could not find specified id: #{id}"
        end

        asset
      end

      def load_asset_by_uri(uri)
        filename, params = AssetURI.parse(uri)

        # Internal assertion, should be routed through load_asset_by_id_uri
        if params.key?(:id)
          raise ArgumentError, "expected uri to have no id: #{uri}"
        end

        type = params[:type]
        load_path, logical_path = paths_split(self.paths, filename)

        if !file?(filename)
          raise FileNotFound, "could not find file: #{filename}"
        elsif type && !resolve_path_transform_type(filename, type)
          raise ConversionError, "could not convert to type: #{type}"
        elsif !load_path
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

        if type
          asset[:content_type] = type
          asset[:logical_path] += mime_types[type][:extensions].first
        end

        processed_processors = unwrap_preprocessors(file_type) +
          unwrap_engines(engine_extnames).reverse +
          unwrap_transformer(file_type, type) +
          unwrap_postprocessors(type)

        bundled_processors = params[:skip_bundle] ? [] : unwrap_bundle_processors(type)

        processors = bundled_processors.any? ? bundled_processors : processed_processors
        processors += unwrap_encoding_processors(params[:encoding])

        # Read into memory and process if theres a processor pipeline or the
        # content type is text.
        if processors.any? || mime_type_charset_detecter(type)
          asset.merge!(process(
            [method(:read_input)] + processors,
            asset[:uri],
            asset[:filename],
            asset[:load_path],
            asset[:name],
            asset[:content_type]
          ))
        else
          asset.merge!({
            encoding: Encoding::BINARY,
            length: self.stat(asset[:filename]).size,
            digest: file_digest(asset[:filename]),
            metadata: {}
          })
        end

        metadata = asset[:metadata]
        metadata[:dependency_paths] = Set.new(metadata[:dependency_paths]).merge([asset[:filename]])
        metadata[:dependency_sources_digest] = files_digest(metadata[:dependency_paths])

        asset[:integrity] = integrity_uri(asset[:digest], asset[:content_type])

        asset[:id]  = pack_hexdigest(digest(asset))
        asset[:uri] = AssetURI.build(filename, params.merge(id: asset[:id]))

        # TODO: Avoid tracking Asset mtime
        asset[:mtime] = metadata[:dependency_paths].map { |p| stat(p).mtime.to_i }.max

        asset
      end
  end
end
