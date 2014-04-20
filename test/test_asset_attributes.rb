require 'sprockets_test'

class TestAssetAttributes < Sprockets::TestCase
  test "engine extensions" do
    assert_equal [], pathname("empty").engine_extensions
    assert_equal [], pathname("gallery.js").engine_extensions
    assert_equal [".coffee"], pathname("application.js.coffee").engine_extensions
    assert_equal [".coffee", ".erb"], pathname("project.js.coffee.erb").engine_extensions
    assert_equal [".erb"], pathname("gallery.css.erb").engine_extensions
    assert_equal [".erb"], pathname("gallery.erb").engine_extensions
    assert_equal [], pathname("jquery.js").engine_extensions
    assert_equal [], pathname("jquery.min.js").engine_extensions
    assert_equal [], pathname("jquery.tmpl.min.js").engine_extensions
    assert_equal [".erb"], pathname("jquery.js.erb").engine_extensions
    assert_equal [".erb"], pathname("jquery.min.js.erb").engine_extensions
    assert_equal [".coffee"], pathname("jquery.min.coffee").engine_extensions
    assert_equal [".erb"], pathname("jquery.csv.min.js.erb").engine_extensions
    assert_equal [".coffee", ".erb"], pathname("jquery.csv.min.js.coffee.erb").engine_extensions

    env = Sprockets::Environment.new
    env.register_engine '.ms', Class.new
    assert_equal [".jst", ".ms"], Sprockets::AssetAttributes.new(env, "foo.jst.ms").engine_extensions
  end

  private
    def pathname(path)
      env = Sprockets::Environment.new
      env.append_path fixture_path("default")
      Sprockets::AssetAttributes.new(env, path)
    end
end
