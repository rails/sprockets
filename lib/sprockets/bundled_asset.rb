module Sprockets
  class BundledAsset < Asset
    # Deprecated: Access Processed Asset subcomponents of bundled asset.
    #
    # Use BundledAsset#source_paths instead. Keeping a full copy of the
    # bundle's processed assets in memory (and in cache) is expensive and
    # redundant. The common use case is to relink to the assets anyway.
    # #source_paths provides that reference.
    #
    # Returns Array of ProcessedAssets.
    def to_a
      @required_asset_hashes.map do |hash|
        ProcessedAsset.new(hash)
      end
    end

    def source_paths
      to_a.map(&:digest_path)
    end
  end
end
