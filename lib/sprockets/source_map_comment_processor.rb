# frozen_string_literal: true
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

      asset.metadata.merge(
        data: asset.source + (comment % map.digest_path),
        links: asset.links + [asset.uri, map.uri]
      )
    end
  end
end
