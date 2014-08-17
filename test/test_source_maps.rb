require 'sprockets_test'
require 'sprockets/bundle'

class TestSourceMaps < Sprockets::TestCase
  def setup
    @environment = Sprockets::Environment.new
    @environment.append_path fixture_path('source-maps')
  end

  test "builds a source map for js files" do
    asset = @environment['child.js']
    map = asset.metadata[:map]
    assert_equal ['child'], map.sources
  end

  test "builds a minified source map" do
    @environment.js_compressor = :uglifier

    asset = @environment['application.js']
    map = asset.metadata[:map]
    assert map.all? {|mapping| mapping.generated.line == 1 }
    assert_equal %w[project users application], map.sources
  end

  test "builds a source map with js dependency" do
    asset = @environment['parent.js']
    map = asset.metadata[:map]
    assert_equal %w[child users parent], map.sources
  end
end
