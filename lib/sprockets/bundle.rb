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
      env      = input[:environment]
      filename = input[:filename]
      type     = input[:content_type]

      cache = Hash.new do |h, uri|
        h[uri] = env.find_asset_by_uri(uri)
      end

      find_required = proc { |path| cache[path].metadata[:required] }
      uri = "file://#{URI::Generic::DEFAULT_PARSER.escape(filename)}?type=#{type}&processed"
      required = Utils.dfs(uri, &find_required)
      stubbed  = Utils.dfs(cache[uri].metadata[:stubbed], &find_required)
      required.subtract(stubbed)
      assets = required.map { |path| cache[path] }

      env.process_bundle_reducers(assets, env.unwrap_bundle_reducers(type))
    end
  end
end
