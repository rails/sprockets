require 'sprockets_test'

class TestStylesheetBundle < Sprockets::TestCase
  test "bundle single stylesheet file" do
    environment = Sprockets::Environment.new
    environment.append_path fixture_path('asset')

    filename = fixture_path('asset/project.css')
    assert File.exist?(filename)

    input = {
      environment: environment,
      uri: "file://#{filename}?type=text/css",
      filename: filename,
      content_type: 'text/css',
      metadata: {}
    }

    data = ".project {}\n"
    result = Sprockets::Bundle.call(input)
    assert_equal data, result[:data]
    assert_equal ["file-digest:#{filename}"], result[:cache_dependencies].to_a.sort
  end

  test "bundle multiple stylesheet files" do
    environment = Sprockets::Environment.new
    environment.append_path fixture_path('asset')

    filename = fixture_path('asset/require_self.css')
    assert File.exist?(filename)

    input = {
      environment: environment,
      uri: "file://#{filename}?type=text/css",
      filename: filename,
      content_type: 'text/css',
      metadata: {}
    }

    data = "/* b.css */\n\nb { display: none }\n/*\n\n\n\n */\n\n\nbody {}\n.project {}\n"
    result = Sprockets::Bundle.call(input)
    assert_equal data, result[:data]
    assert_equal [
      "file-digest:" + fixture_path('asset/project.css'),
      "file-digest:" + fixture_path('asset/require_self.css'),
      "file-digest:" + fixture_path('asset/tree/all/b.css')
    ], result[:cache_dependencies].to_a.sort
  end

  test "bundle single javascript file" do
    environment = Sprockets::Environment.new
    environment.append_path fixture_path('asset')

    filename = fixture_path('asset/project.js.erb')
    assert File.exist?(filename)

    input = {
      environment: environment,
      uri: "file://#{filename}?type=application/javascript",
      filename: filename,
      content_type: 'application/javascript',
      metadata: {}
    }

    data = "var Project = {\n  find: function(id) {\n  }\n};\n"
    result = Sprockets::Bundle.call(input)
    assert_equal data, result[:data]
    assert_equal ["file-digest:#{filename}"], result[:cache_dependencies].to_a.sort
  end

  test "bundle multiple javascript files" do
    environment = Sprockets::Environment.new
    environment.append_path fixture_path('asset')

    filename = fixture_path('asset/application.js')
    assert File.exist?(filename)

    input = {
      environment: environment,
      uri: "file://#{filename}?type=application/javascript",
      filename: filename,
      content_type: 'application/javascript',
      metadata: {}
    }

    data = "var Project = {\n  find: function(id) {\n  }\n};\nvar Users = {\n  find: function(id) {\n  }\n};\n\n\n\ndocument.on('dom:loaded', function() {\n  $('search').focus();\n});\n"
    result = Sprockets::Bundle.call(input)
    assert_equal data, result[:data]
    assert_equal [
      "file-digest:" + fixture_path('asset/application.js'),
      "file-digest:" + fixture_path('asset/project.js.erb'),
      "file-digest:" + fixture_path('asset/users.js.erb')
    ], result[:cache_dependencies].to_a.sort
  end
end
