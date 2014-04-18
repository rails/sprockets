module Sprockets
  class BundledAsset < Asset
    def to_a
      @required_asset_hashes.map do |hash|
        ProcessedAsset.new(hash)
      end
    end
  end
end
