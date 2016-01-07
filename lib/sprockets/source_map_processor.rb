require 'set'

module Sprockets
  class SourceMapProcessor
    def self.call(input)
      case input[:content_type]
      when "application/js-sourcemap+json"
        accept = "application/javascript"
      when "application/css-sourcemap+json"
        accept = "text/css"
      else
        fail input[:content_type]
      end

      links = Set.new(input[:metadata][:links])

      env = input[:environment]

      uri, _ = env.resolve!(input[:filename], accept: accept)
      asset  = env.load(uri)
      map    = asset.metadata[:map] || []

      map.map { |m| m[:source] }.uniq.compact.each do |source|
        # TODO: Resolve should expect fingerprints
        fingerprint = source[/-([0-9a-f]{7,128})\.[^.]+\z/, 1]
        if fingerprint
          path = source.sub("-#{fingerprint}", "")
        else
          path = source
        end
        uri, _ = env.resolve!(path)
        links << env.load(uri).uri
      end

      json = env.encode_json_source_map(map, filename: asset.logical_path)

      { data: json, links: links }
    end
  end
end
