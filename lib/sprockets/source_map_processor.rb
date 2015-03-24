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
      asset = env.load(uri)
      map = asset.metadata[:map] || []

      map.map { |m| m[:source] }.uniq.compact.each do |source|
        uri, _ = env.resolve!(source)
        links << env.load(uri).uri
      end

      json = env.encode_json_source_map(map, filename: asset.logical_path)

      { data: json, links: links }
    end
  end
end
