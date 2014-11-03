require 'sprockets/asset_uri'

module Sprockets
  # Internal: Bundle processor takes a single file asset and prepends all the
  # `:required` URIs to the contents.
  #
  # Uses pipeline metadata:
  #
  #   :required - Ordered Set of asset URIs to prepend
  #   :stubbed  - Set of asset URIs to substract from the required set.
  #
  # Also see DirectiveProcessor.
  class Bundle
    def self.call(input)
      env  = input[:environment]
      type = input[:content_type]

      # TODO: Rebuilding this URI is a bit of a smell
      processed_uri = AssetURI.build(input[:filename], type: type, skip_bundle: true)

      cache = Hash.new do |h, uri|
        h[uri] = env.load(uri)
      end

      find_required = proc { |uri| cache[uri].metadata[:required] }
      required = Utils.dfs(processed_uri, &find_required)
      stubbed  = Utils.dfs(cache[processed_uri].metadata[:stubbed], &find_required)
      required.subtract(stubbed)
      assets = required.map { |uri| cache[uri] }

      dependency_paths = Set.new
      (required + stubbed).each do |uri|
        dependency_paths += cache[uri].metadata[:dependency_paths]
      end

      env.process_bundle_reducers(assets, env.unwrap_bundle_reducers(type)).merge(dependency_paths: dependency_paths, included: assets.map(&:uri))
    end
  end
end
