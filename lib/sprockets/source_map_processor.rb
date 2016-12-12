# frozen_string_literal: true
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
      map    = asset.metadata[:map]

      # TODO: Because of the default piplene hack we have to apply dependencies
      #       from compiled asset to the source map, otherwise the source map cache
      #       will never detect the changes from directives
      dependencies = Set.new(input[:metadata][:dependencies])
      dependencies.merge(asset.metadata[:dependencies])

      map["file"] = PathUtils.split_subpath(input[:load_path], input[:filename])
      sources = map["sections"] ? map["sections"].map { |s| s["map"]["sources"] }.flatten : map["sources"]

      sources.each do |source|
        source = PathUtils.join(File.dirname(map["file"]), source)
        uri, _ = env.resolve!(source)
        links << uri
      end

      json = JSON.generate(map)

      { data: json, links: links, dependencies: dependencies }
    end
  end
end
