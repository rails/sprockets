require "sprockets_test"

class StorageTest < Sprockets::TestCase
  test "storing and retreiving assets from storage" do
    store = Sprockets::Storage.new({})

    filename = File.join(fixture_path('default'), "hello.txt")
    asset    = Sprockets::StaticAsset.new(filename)

    assert_nil store[asset.digest]

    assert store[asset.digest] = asset
    assert_equal asset, store[asset.digest]
  end
end
