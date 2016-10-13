# frozen_string_literal: true
require 'sprockets/uri_utils'
require 'sprockets/path_utils'

module Sprockets
  class SourceMapCommentProcessor
    def self.call(input)
      case input[:content_type]
      when "application/javascript"
        comment = "\n//# sourceMappingURL=%s"
        map_type = "application/js-sourcemap+json"
      when "text/css"
        comment = "\n/*# sourceMappingURL=%s */"
        map_type = "application/css-sourcemap+json"
      else
        fail input[:content_type]
      end

      env = input[:environment]

      uri, _ = env.resolve!(input[:filename], accept: input[:content_type])
      asset = env.load(uri)

      uri, _ = env.resolve!(input[:filename], accept: map_type)
      map = env.load(uri)

      uri, params = URIUtils.parse_asset_uri(input[:uri])
      uri = env.expand_from_root(params[:index_alias]) if params[:index_alias]
      path = PathUtils.relative_path_from(PathUtils.split_subpath(input[:load_path], uri), map.digest_path)

      asset.metadata.merge(
        data: asset.source + (comment % path),
        links: asset.links + [asset.uri, map.uri]
      )
    end
  end
end
