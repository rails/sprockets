require 'sprockets_test'

class TestEnginePathname < Sprockets::TestCase
  include Sprockets

  test "identity initialization" do
    path = EnginePathname.new("javascripts/application.js.coffee")
    assert EnginePathname.new(path).equal?(path)
  end

  test "basename with extensions" do
    assert_equal "empty",
      EnginePathname.new("empty").basename_without_extensions.to_s
    assert_equal "gallery",
      EnginePathname.new("gallery.js").basename_without_extensions.to_s
    assert_equal "application",
      EnginePathname.new("application.js.coffee").basename_without_extensions.to_s
    assert_equal "project",
      EnginePathname.new("project.js.coffee.erb").basename_without_extensions.to_s
    assert_equal "gallery",
      EnginePathname.new("gallery.css.erb").basename_without_extensions.to_s
  end

  test "extensions" do
    assert_equal [],
      EnginePathname.new("empty").extensions
    assert_equal [".js"],
      EnginePathname.new("gallery.js").extensions
    assert_equal [".js", ".coffee"],
      EnginePathname.new("application.js.coffee").extensions
    assert_equal [".js", ".coffee", ".erb"],
      EnginePathname.new("project.js.coffee.erb").extensions
    assert_equal [".css", ".erb"],
      EnginePathname.new("gallery.css.erb").extensions
  end

  test "format_extension" do
    assert_equal nil, EnginePathname.new("empty").format_extension
    assert_equal ".js", EnginePathname.new("gallery.js").format_extension
    assert_equal ".js", EnginePathname.new("application.js.coffee").format_extension
    assert_equal ".js", EnginePathname.new("project.js.coffee.erb").format_extension
    assert_equal ".css", EnginePathname.new("gallery.css.erb").format_extension
    assert_equal nil, EnginePathname.new("gallery.erb").format_extension
    assert_equal nil, EnginePathname.new("gallery.foo").format_extension
    assert_equal ".js", EnginePathname.new("jquery.js").format_extension
    assert_equal ".js", EnginePathname.new("jquery.min.js").format_extension
    assert_equal ".js", EnginePathname.new("jquery.tmpl.js").format_extension
    assert_equal ".js", EnginePathname.new("jquery.tmpl.min.js").format_extension
  end

  test "engine_extensions" do
    assert_equal [], EnginePathname.new("empty").engine_extensions
    assert_equal [], EnginePathname.new("gallery.js").engine_extensions
    assert_equal [".coffee"],
      EnginePathname.new("application.js.coffee").engine_extensions
    assert_equal [".coffee", ".erb"],
      EnginePathname.new("project.js.coffee.erb").engine_extensions
    assert_equal [".erb"], EnginePathname.new("gallery.css.erb").engine_extensions
    assert_equal [".erb"], EnginePathname.new("gallery.erb").engine_extensions
    assert_equal [], EnginePathname.new("jquery.js").engine_extensions
    assert_equal [], EnginePathname.new("jquery.min.js").engine_extensions
    assert_equal [], EnginePathname.new("jquery.tmpl.min.js").engine_extensions
    assert_equal [".erb"], EnginePathname.new("jquery.js.erb").engine_extensions
    assert_equal [".erb"], EnginePathname.new("jquery.min.js.erb").engine_extensions
    assert_equal [".coffee"],
      EnginePathname.new("jquery.min.coffee").engine_extensions
  end

  test "without engine extensions" do
    assert_equal "gallery.js",
      EnginePathname.new("gallery.js").without_engine_extensions.to_s
    assert_equal "application.js",
      EnginePathname.new("application.js.coffee").without_engine_extensions.to_s
    assert_equal "project.js",
      EnginePathname.new("project.js.coffee.erb").without_engine_extensions.to_s
    assert_equal "gallery",
      EnginePathname.new("gallery.erb").without_engine_extensions.to_s
    assert_equal "jquery.tmpl.min.js",
      EnginePathname.new("jquery.tmpl.min.js").without_engine_extensions.to_s
    assert_equal "jquery.min",
      EnginePathname.new("jquery.min.coffee").without_engine_extensions.to_s
  end

  test "content_type" do
    assert_equal "application/octet-stream",
      EnginePathname.new("empty").content_type
    assert_equal "application/javascript",
      EnginePathname.new("gallery.js").content_type
    assert_equal "application/javascript",
      EnginePathname.new("application.js.coffee").content_type
    assert_equal "application/javascript",
      EnginePathname.new("project.js.coffee.erb").content_type
    assert_equal "text/css",
      EnginePathname.new("gallery.css.erb").content_type
    assert_equal "application/javascript",
      EnginePathname.new("jquery.tmpl.min.js").content_type

    if Tilt::CoffeeScriptTemplate.respond_to?(:default_mime_type)
      assert_equal "application/javascript",
        EnginePathname.new("application.coffee").content_type
    end
  end
end
