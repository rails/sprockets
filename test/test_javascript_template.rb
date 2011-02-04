require "sprockets_test"

class JavascriptTemplateTest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new
    @env.paths << fixture_path('jst')
  end

  test "processing a source file with format and extension" do
    assert_equal <<-EOS, asset("hello.js.jst").to_s
(function() {
  if (!window.templates) window.templates = {};
  window.templates["hello"] = "hello: <%= name %>\\n";
})();
    EOS
  end

  test "processing a source file with only extension" do
    assert_equal <<-EOS, asset("people/list.jst").to_s
(function() {
  if (!window.templates) window.templates = {};
  window.templates["people/list"] = "<% _.each(people, function(name) { %>\\n<li><%= name %></li>\\n<% }); %>\\n";
})();
    EOS
  end

  def asset(logical_path)
    Sprockets::ConcatenatedAsset.new(@env, @env.resolve(logical_path))
  end
end
