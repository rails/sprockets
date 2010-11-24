require "sprockets_test"

class SourceFileTest < Sprockets::TestCase
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
