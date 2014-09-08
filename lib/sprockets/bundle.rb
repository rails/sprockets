require 'uri'

module Sprockets
  # Internal: Bundle processor takes a single file asset and prepends all the
  # `:required_paths` to the contents.
  #
  # Uses pipeline metadata:
  #
  #   :required_paths - Ordered Set of asset filenames to prepend
  #   :stubbed_paths  - Set of asset filenames to substract from the
  #                     required path set.
  #
  # Also see DirectiveProcessor.
  class Bundle
    def self.call(input)
      env      = input[:environment]
      filename = input[:filename]
      type     = input[:content_type]

      cache = Hash.new do |h, path|
        uri = "file://#{URI::Generic::DEFAULT_PARSER.escape(path)}?type=#{type}&processed"
        h[path] = env.find_asset_by_uri(uri).to_hash
      end

      find_required_paths = proc { |path| cache[path][:metadata][:required_paths] }
      required_paths = Utils.dfs(filename, &find_required_paths)
      stubbed_paths  = Utils.dfs(cache[filename][:metadata][:stubbed_paths], &find_required_paths)
      required_paths.subtract(stubbed_paths)
      assets = required_paths.map { |path| cache[path] }

      env.process_bundle_reducers(assets, env.unwrap_bundle_reducers(type))
    end
  end
end
