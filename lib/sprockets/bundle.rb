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
      processed_uri = AssetURI.merge(input[:uri], processed: true)

      cache = Hash.new do |h, uri|
        h[uri] = env.find_asset_by_uri(uri)
      end

      find_required = proc { |uri| cache[uri].metadata[:required] }
      required = Utils.dfs(processed_uri, &find_required)
      stubbed  = Utils.dfs(cache[processed_uri].metadata[:stubbed], &find_required)
      required.subtract(stubbed)
      assets = required.map { |uri| cache[uri] }

      env.process_bundle_reducers(assets, env.unwrap_bundle_reducers(type)).merge(included: assets.map(&:uri))
    end
  end
end
