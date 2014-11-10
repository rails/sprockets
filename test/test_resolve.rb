require 'sprockets_test'

class TestResolve < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
  end

  test "resolve in default environment" do
    @env.append_path(fixture_path('default'))

    assert_equal fixture_path('default/gallery.js'),
      @env.resolve("gallery.js")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min.js")
    assert_equal fixture_path('default/manifest.js.yml'),
      @env.resolve('manifest.js.yml')
    refute @env.resolve("null")
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

  test "resolve under load path" do
    @env.append_path(scripts = fixture_path('resolve/javascripts'))
    @env.append_path(styles = fixture_path('resolve/stylesheets'))

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', load_paths: [scripts])
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', load_paths: [styles])

    refute @env.resolve('foo.js', load_paths: [styles])
    refute @env.resolve('foo.css', load_paths: [scripts])
  end

  test "resolve absolute" do
    @env.append_path(fixture_path('default'))

    assert_equal fixture_path('default/gallery.js'),
      @env.resolve(fixture_path('default/gallery.js'))
    assert_equal fixture_path('default/gallery.js'),
      @env.resolve(fixture_path('default/app/../gallery.js'))
    assert_equal fixture_path('default/gallery.js'),
      @env.resolve(fixture_path('default/gallery.js'), accept: 'application/javascript')

    refute @env.resolve(fixture_path('default/asset/POW.png'))
    refute @env.resolve(fixture_path('default/missing'))
    refute @env.resolve(fixture_path('default/gallery.js'), accept: 'text/css')
  end

  test "resolve extension before accept type" do
    @env.append_path(fixture_path('resolve/javascripts'))
    @env.append_path(fixture_path('resolve/stylesheets'))

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: 'application/javascript')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: '*/*')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: '*/*')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: 'text/css, */*')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: 'application/javascript, */*')
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

  test "locate asset uri" do
    @env.append_path(fixture_path('default'))

    assert_equal "file://#{fixture_path('default/gallery.js')}?type=application/javascript",
      @env.locate("gallery.js")
    assert_equal "file://#{fixture_path('default/coffee/foo.coffee')}?type=application/javascript",
      @env.locate("coffee/foo.js")
    assert_equal "file://#{fixture_path('default/manifest.js.yml')}?type=text/yaml",
      @env.locate("manifest.js.yml")

    assert_equal "file://#{fixture_path('default/gallery.js')}?type=application/javascript",
      @env.locate("gallery", accept: 'application/javascript')
    assert_equal "file://#{fixture_path('default/coffee/foo.coffee')}?type=text/coffeescript",
      @env.locate("coffee/foo", accept: 'text/coffeescript')
  end

  test "locate asset uri under load path" do
    @env.append_path(scripts = fixture_path('resolve/javascripts'))
    @env.append_path(styles = fixture_path('resolve/stylesheets'))

    assert_equal "file://#{fixture_path('resolve/javascripts/foo.js')}?type=application/javascript",
      @env.locate('foo.js', load_paths: [scripts])
    assert_equal "file://#{fixture_path('resolve/stylesheets/foo.css')}?type=text/css",
      @env.locate('foo.css', load_paths: [styles])

    refute @env.locate('foo.js', load_paths: [styles])
    refute @env.locate('foo.css', load_paths: [scripts])
  end
end
