require 'sprockets_test'

class TestResolve < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
  end

  test "resolve in default environment" do
    @env.append_path(fixture_path('default'))

    assert_equal fixture_path('default/gallery.js'),
      @env.resolve("gallery.js")
    assert_equal fixture_path('default/gallery.js'),
      @env.resolve(Pathname.new("gallery.js"))
    assert_equal fixture_path('default/coffee/foo.coffee'),
      @env.resolve("coffee/foo.js")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min.js")
    assert_equal fixture_path('default/manifest.js.yml'),
      @env.resolve('manifest.js.yml')

    refute @env.resolve_all("null").first
    assert_raises(Sprockets::FileNotFound) do
      @env.resolve("null")
    end
  end

  test "resolve accept type list before paths" do
    @env.append_path(fixture_path('resolve/javascripts'))
    @env.append_path(fixture_path('resolve/stylesheets'))

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript, text/css')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'text/css, application/javascript')
  end

  test "verify all logical paths" do
    Dir.entries(Sprockets::TestCase::FIXTURE_ROOT).each do |dir|
      unless %w( . ..).include?(dir)
        @env.append_path(fixture_path(dir))
      end
    end

    @env.logical_paths.each do |logical_path, filename|
      assert_equal filename, @env.resolve_all(logical_path).first,
        "Expected #{logical_path.inspect} to resolve to #{filename}"
    end
  end
end
