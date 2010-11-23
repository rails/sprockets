require "sprockets_test"

class SourceFileTest < Sprockets::TestCase
  test "basename" do
    assert_equal "application.js.coffee", source_file("application.js.coffee").basename
  end

  test "extensions" do
    assert_equal [], source_file("empty").extensions
    assert_equal [".js"], source_file("gallery.js").extensions
    assert_equal [".js", ".coffee"], source_file("application.js.coffee").extensions
    assert_equal [".js", ".coffee", ".erb"], source_file("project.js.coffee.erb").extensions
    assert_equal [".css", ".erb"], source_file("gallery.css.erb").extensions
  end

  test "format_extension" do
    assert_equal nil, source_file("empty").format_extension
    assert_equal ".js", source_file("gallery.js").format_extension
    assert_equal ".js", source_file("application.js.coffee").format_extension
    assert_equal ".js", source_file("project.js.coffee.erb").format_extension
    assert_equal ".css", source_file("gallery.css.erb").format_extension
  end

  test "engine_extensions" do
    assert_equal [], source_file("empty").engine_extensions
    assert_equal [], source_file("gallery.js").engine_extensions
    assert_equal [".coffee"], source_file("application.js.coffee").engine_extensions
    assert_equal [".coffee", ".erb"], source_file("project.js.coffee.erb").engine_extensions
    assert_equal [".erb"], source_file("gallery.css.erb").engine_extensions
  end

  test "content_type" do
    assert_equal "application/octet-stream", source_file("empty").content_type
    assert_equal "application/javascript", source_file("gallery.js").content_type
    assert_equal "application/javascript", source_file("application.js.coffee").content_type
    assert_equal "application/javascript", source_file("project.js.coffee.erb").content_type
    assert_equal "text/css", source_file("gallery.css.erb").content_type
  end

  test "directive_parser" do
    file = source_file("application.js.coffee")
    assert_kind_of Sprockets::DirectiveParser, file.directive_parser
    assert_equal file.source, file.directive_parser.source
  end

  test "directives" do
    assert_equal [], source_file("empty").directives
    assert_equal [["require", "project.js"]], source_file("application.js.coffee").directives
  end

  test "header" do
    assert_equal "", source_file("empty").header
    assert_equal "# My Application", source_file("application.js.coffee").header
  end

  test "body" do
    assert_equal "", source_file("empty").body
    assert_equal "\nhello()\n", source_file("application.js.coffee").body
  end

  test "mtime" do
    assert_equal File.mtime(fixture_path("default/empty")), source_file("empty").mtime
  end

  def source_file(path)
    Sprockets::SourceFile.new(fixture_path("default/#{path}"))
  end
end
