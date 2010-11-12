require "sprockets_test"

class AssetTest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path("default")
  end

  test "asset source" do
    asset = @env["application.js"]
    assert_equal "(function() {\n  var Project;\n  window.Project = (function() {\n    Project = function() {};\n    Project.prototype.VERSION = 1.0;\n    return Project;\n  })();\n}).call(this);\n(function() {\n  hello();\n}).call(this);\n", asset.source
  end
end
