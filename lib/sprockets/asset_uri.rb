require 'sprockets/errors'
require 'uri'

module Sprockets
  module AssetURI
    def build_asset_uri(path, params = {})
      uri = "file://#{URI::Generic::DEFAULT_PARSER.escape(path)}"
      query = []
      query << "type=#{params[:type]}" if params[:type]
      query << "processed" if params[:processed]
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

      return path, params
    end

    def update_asset_uri(str, new_params = {})
      path, params = parse_asset_uri(str)
      build_asset_uri(path, params.merge(new_params))
    end
  end
end
