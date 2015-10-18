require 'sprockets_test'

class TestLoader < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
    @env.append_path(fixture_path('default'))
  end

  test "load asset by uri" do
    assert asset = @env.load("file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript")
    assert_equal fixture_path('default/gallery.js'), asset.filename
    assert_equal 'application/javascript', asset.content_type
    assert_equal '828e4be75f8bf69529b5d618dd12a6144d58d47cf4c3a9e3f64b0b8812008dab', asset.etag

    assert asset = @env.load(asset.uri)
    assert_equal fixture_path('default/gallery.js'), asset.filename
    assert_equal 'application/javascript', asset.content_type
    assert_equal '828e4be75f8bf69529b5d618dd12a6144d58d47cf4c3a9e3f64b0b8812008dab', asset.etag

    assert asset = @env.load("file://#{fixture_path_for_uri('default/gallery.css.erb')}?type=text/css")
    assert_equal fixture_path('default/gallery.css.erb'), asset.filename
    assert_equal 'text/css', asset.content_type

    assert asset = @env.load(Pathname.new("file://#{fixture_path_for_uri('default/gallery.css.erb')}?type=text/css"))
    assert_equal fixture_path('default/gallery.css.erb'), asset.filename
    assert_equal 'text/css', asset.content_type

    bad_id = "0000000000000000000000000000000000000000"
    assert asset = @env.load("file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript&id=#{bad_id}")
    assert_equal fixture_path('default/gallery.js'), asset.filename
    assert_equal 'application/javascript', asset.content_type

    assert_raises Sprockets::FileNotFound do
      @env.load("file://#{fixture_path_for_uri('default/missing.js')}?type=application/javascript")
    end

    assert_raises Sprockets::ConversionError do
      @env.load("file://#{fixture_path_for_uri('default/gallery.js')}?type=text/css")
    end
  end
end
