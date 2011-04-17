require 'sprockets_test'

class TestPathname < Sprockets::TestCase
  include Sprockets

  test "identity initialization" do
    path = Pathname.new("javascripts/application.js.coffee")
    assert Pathname.new(path).equal?(path)
  end

  test "construct from pathname" do
    pathname = Pathname.new("javascripts/application.js.coffee").expand_path
    assert_equal pathname.to_s, Pathname.new(pathname).to_s
  end

  test "basename with extensions" do
    assert_equal "empty",
      Pathname.new("empty").basename_without_extensions.to_s
    assert_equal "gallery",
      Pathname.new("gallery.js").basename_without_extensions.to_s
    assert_equal "application",
      Pathname.new("application.js.coffee").basename_without_extensions.to_s
    assert_equal "project",
      Pathname.new("project.js.coffee.erb").basename_without_extensions.to_s
    assert_equal "gallery",
      Pathname.new("gallery.css.erb").basename_without_extensions.to_s
  end

  test "extensions" do
    assert_equal [],
      Pathname.new("empty").extensions
    assert_equal [".js"],
      Pathname.new("gallery.js").extensions
    assert_equal [".js", ".coffee"],
      Pathname.new("application.js.coffee").extensions
    assert_equal [".js", ".coffee", ".erb"],
      Pathname.new("project.js.coffee.erb").extensions
    assert_equal [".css", ".erb"],
      Pathname.new("gallery.css.erb").extensions
  end

  test "format_extension" do
    assert_equal nil, Pathname.new("empty").format_extension
    assert_equal ".js", Pathname.new("gallery.js").format_extension
    assert_equal ".js", Pathname.new("application.js.coffee").format_extension
    assert_equal ".js", Pathname.new("project.js.coffee.erb").format_extension
    assert_equal ".css", Pathname.new("gallery.css.erb").format_extension
    assert_equal nil, Pathname.new("gallery.erb").format_extension
    assert_equal nil, Pathname.new("gallery.foo").format_extension
    assert_equal ".js", Pathname.new("jquery.js").format_extension
    assert_equal ".js", Pathname.new("jquery.min.js").format_extension
    assert_equal ".js", Pathname.new("jquery.tmpl.js").format_extension
    assert_equal ".js", Pathname.new("jquery.tmpl.min.js").format_extension
  end

  test "engine_extensions" do
    assert_equal [], Pathname.new("empty").engine_extensions
    assert_equal [], Pathname.new("gallery.js").engine_extensions
    assert_equal [".coffee"],
      Pathname.new("application.js.coffee").engine_extensions
    assert_equal [".coffee", ".erb"],
      Pathname.new("project.js.coffee.erb").engine_extensions
    assert_equal [".erb"], Pathname.new("gallery.css.erb").engine_extensions
    assert_equal [".erb"], Pathname.new("gallery.erb").engine_extensions
    assert_equal [], Pathname.new("jquery.js").engine_extensions
    assert_equal [], Pathname.new("jquery.min.js").engine_extensions
    assert_equal [], Pathname.new("jquery.tmpl.min.js").engine_extensions
    assert_equal [".erb"], Pathname.new("jquery.js.erb").engine_extensions
    assert_equal [".erb"], Pathname.new("jquery.min.js.erb").engine_extensions
    assert_equal [".coffee"],
      Pathname.new("jquery.min.coffee").engine_extensions
  end

  test "without engine extensions" do
    assert_equal "gallery.js",
      Pathname.new("gallery.js").without_engine_extensions.to_s
    assert_equal "application.js",
      Pathname.new("application.js.coffee").without_engine_extensions.to_s
    assert_equal "project.js",
      Pathname.new("project.js.coffee.erb").without_engine_extensions.to_s
    assert_equal "gallery",
      Pathname.new("gallery.erb").without_engine_extensions.to_s
    assert_equal "jquery.tmpl.min.js",
      Pathname.new("jquery.tmpl.min.js").without_engine_extensions.to_s
    assert_equal "jquery.min",
      Pathname.new("jquery.min.coffee").without_engine_extensions.to_s
  end

  test "content_type" do
    assert_equal "application/octet-stream",
      Pathname.new("empty").content_type
    assert_equal "application/javascript",
      Pathname.new("gallery.js").content_type
    assert_equal "application/javascript",
      Pathname.new("application.js.coffee").content_type
    assert_equal "application/javascript",
      Pathname.new("project.js.coffee.erb").content_type
    assert_equal "text/css",
      Pathname.new("gallery.css.erb").content_type
    assert_equal "application/javascript",
      Pathname.new("jquery.tmpl.min.js").content_type

    if Tilt::CoffeeScriptTemplate.respond_to?(:default_mime_type)
      assert_equal "application/javascript",
        Pathname.new("application.coffee").content_type
    end
  end

  test "index" do
    assert_equal "mobile/index.js", Pathname.new("mobile.js").index.to_s
    assert_equal "print/index.css", Pathname.new("print.css").index.to_s
    assert_equal "mobile/index.js", Pathname.new("mobile/index.js").index.to_s
    assert_equal "main/mobile/index.js", Pathname.new("main/mobile.js").index.to_s
    assert_equal "mobile/index", Pathname.new("mobile").index.to_s
    assert_equal "./mobile/index.js", Pathname.new("./mobile/index.js").index.to_s
  end

  test "fingerprint" do
    assert_nil Pathname.new("print.css").fingerprint
    assert_equal "f7531e2d0ea27233ce00b5f01c5bf335", Pathname.new("print-f7531e2d0ea27233ce00b5f01c5bf335.css").fingerprint
  end

  test "with fingerprint" do
    assert_equal "print-f7531e2d0ea27233ce00b5f01c5bf335.css",
      Pathname.new("print.css").with_fingerprint("f7531e2d0ea27233ce00b5f01c5bf335").to_s
    assert_equal "/stylesheets/print-f7531e2d0ea27233ce00b5f01c5bf335.css",
      Pathname.new("/stylesheets/print-37b51d194a7513e45b56f6524f2d51f2.css").with_fingerprint("f7531e2d0ea27233ce00b5f01c5bf335").to_s
  end
end
