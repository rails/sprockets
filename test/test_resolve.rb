require 'sprockets_test'

class TestResolve < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
  end

  test "resolve transform type for svg" do
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', 'image/svg+xml')
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', '*/*')
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', nil)
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', 'image/*')
    assert_equal 'image/png',
      @env.resolve_transform_type('image/svg+xml', 'image/png')
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', 'image/svg+xml, image/png')
    assert_equal 'image/png',
      @env.resolve_transform_type('image/svg+xml', 'image/png, image/svg+xml')
    assert_equal 'image/png',
      @env.resolve_transform_type('image/svg+xml', 'image/svg+xml; q=0.8, image/png')
    assert_equal 'image/svg+xml',
      @env.resolve_transform_type('image/svg+xml', 'text/yaml, image/svg+xml, image/png')
    assert_equal 'image/png',
      @env.resolve_transform_type('image/svg+xml', 'text/yaml, image/png, image/svg+xml')
    refute @env.resolve_transform_type('image/svg+xml', 'text/yaml')

    refute @env.resolve_transform_type(nil, 'image/svg+xml')
    refute @env.resolve_transform_type(nil, nil)
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

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript; q=0.8, text/css')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'text/css; q=0.8, application/javascript')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: '*/*; q=0.8, application/javascript')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: '*/*; q=0.8, text/css')
  end

  test "resolve accept type quality in paths" do
    @env.append_path(fixture_path('resolve/javascripts'))

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'application/javascript')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'application/javascript, text/css')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'text/css, application/javascript')

    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'application/javascript; q=0.8, text/css')
    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'text/css; q=0.8, application/javascript')

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: '*/*; q=0.8, application/javascript')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: '*/*; q=0.8, text/css')
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
