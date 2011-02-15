require "sprockets_test"

class StaticAssetTest < Sprockets::TestCase
  def setup
    @fixtures = fixture_path('default')
    @filename = File.join(@fixtures, "hello.txt")
    @asset    = Sprockets::StaticAsset.new(@filename)
  end

  test "serialize to json" do
    json = @asset.to_json
    assert_match "Sprockets::StaticAsset", json
    assert_match @filename, json
    assert_match "33ab5639bfd8e7b95eb1d8d0b87781d4ffea4d5d", json
  end

  test "unserialize from json" do
    asset = JSON.parse({
      'json_class' => "Sprockets::StaticAsset",
      'pathname'   => @filename,
      'mtime'      => File.mtime(@filename),
      'length'     => 12,
      'digest'     => "33ab5639bfd8e7b95eb1d8d0b87781d4ffea4d5d"
    }.to_json)

    assert_kind_of Sprockets::StaticAsset, asset
    assert_equal @filename, asset.pathname.path
    assert_equal File.mtime(@filename), asset.mtime
    assert_equal 12, asset.length
    assert_equal "33ab5639bfd8e7b95eb1d8d0b87781d4ffea4d5d", asset.digest
  end

  test "reciprocal serialization functions" do
    assert_equal @asset, JSON.parse(@asset.to_json)
  end
end
