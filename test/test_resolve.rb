require 'sprockets_test'

class TestResolve < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
  end

  test "resolve in default environment" do
    @env.append_path(fixture_path_for_uri('default'))

    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript",
      resolve("gallery.js")
    assert_equal "file://#{fixture_path_for_uri('default/coffee/foo.coffee')}?type=application/javascript",
      resolve("coffee/foo.js")
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript",
      resolve("jquery.tmpl.min")
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript",
      resolve("jquery.tmpl.min.js")
    assert_equal "file://#{fixture_path_for_uri('default/manifest.js.yml')}?type=text/yaml",
      resolve('manifest.js.yml')
    refute resolve("null")
  end

  test "resolve accept type list before paths" do
    @env.append_path(fixture_path_for_uri('resolve/javascripts'))
    @env.append_path(fixture_path_for_uri('resolve/stylesheets'))

    foo_js_uri  = "file://#{fixture_path_for_uri('resolve/javascripts/foo.js')}?type=application/javascript"
    foo_css_uri = "file://#{fixture_path_for_uri('resolve/stylesheets/foo.css')}?type=text/css"

    assert_equal foo_js_uri, resolve('foo', accept: 'application/javascript')
    assert_equal foo_css_uri, resolve('foo', accept: 'text/css')

    assert_equal foo_js_uri, resolve('foo', accept: 'application/javascript, text/css')
    assert_equal foo_js_uri, resolve('foo', accept: 'text/css, application/javascript')

    assert_equal foo_js_uri, resolve('foo', accept: 'application/javascript; q=0.8, text/css')
    assert_equal foo_js_uri, resolve('foo', accept: 'text/css; q=0.8, application/javascript')

    assert_equal foo_js_uri, resolve('foo', accept: '*/*; q=0.8, application/javascript')
    assert_equal foo_js_uri, resolve('foo', accept: '*/*; q=0.8, text/css')
  end

  test "resolve under load path" do
    @env.append_path(scripts = fixture_path_for_uri('resolve/javascripts'))
    @env.append_path(styles = fixture_path_for_uri('resolve/stylesheets'))

    foo_js_uri  = "file://#{fixture_path_for_uri('resolve/javascripts/foo.js')}?type=application/javascript"
    foo_css_uri = "file://#{fixture_path_for_uri('resolve/stylesheets/foo.css')}?type=text/css"

    assert_equal foo_js_uri, resolve('foo.js', load_paths: [scripts])
    assert_equal foo_css_uri, resolve('foo.css', load_paths: [styles])

    refute resolve('foo.js', load_paths: [styles])
    refute resolve('foo.css', load_paths: [scripts])
  end

  test "resolve absolute" do
    @env.append_path(fixture_path_for_uri('default'))

    gallery_js_uri = "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript"

    assert_equal gallery_js_uri, resolve(fixture_path_for_uri('default/gallery.js'))
    assert_equal gallery_js_uri, resolve(fixture_path_for_uri('default/app/../gallery.js'))
    assert_equal gallery_js_uri, resolve(fixture_path_for_uri('default/gallery.js'), accept: 'application/javascript')

    assert_equal "file://#{fixture_path_for_uri('default/blank.gif')}?type=image/gif",
      resolve(fixture_path_for_uri('default/blank.gif'))
    assert_equal "file://#{fixture_path_for_uri('default/hello.txt')}?type=text/plain",
      resolve(fixture_path_for_uri('default/hello.txt'))
    assert_equal "file://#{fixture_path_for_uri('default/README.md')}",
      resolve(fixture_path_for_uri('default/README.md'))

    refute resolve(fixture_path_for_uri('asset/POW.png'))
    refute resolve(fixture_path_for_uri('default/missing'))
    refute resolve(fixture_path_for_uri('default/gallery.js'), accept: 'text/css')
  end

  test "resolve absolute identity" do
    @env.append_path(fixture_path_for_uri('default'))

    @env.stat_tree(fixture_path_for_uri('default')).each do |expected_path, stat|
      next unless stat.file?
      actual_path, _ = @env.parse_asset_uri(resolve(expected_path))
      assert_equal expected_path, actual_path
    end
  end

  test "resolve relative" do
    @env.append_path(fixture_path_for_uri('default'))

    gallery_js_uri = "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript"

    assert_equal gallery_js_uri, resolve("./gallery.js", base_path: fixture_path_for_uri('default'))
    assert_equal gallery_js_uri, resolve("../gallery.js", base_path: fixture_path_for_uri('default/app'))
    assert_equal gallery_js_uri, resolve("./../gallery.js", base_path: fixture_path_for_uri('default/app'))
    assert_equal gallery_js_uri, resolve("../../gallery.js", base_path: fixture_path_for_uri('default/vendor/gems'))

    refute resolve("./missing.js", base_path: fixture_path_for_uri('default'))
    refute resolve("../asset/application.js", base_path: fixture_path_for_uri('default'))
    refute resolve("../default/gallery.js", base_path: fixture_path_for_uri('app'))
  end

  test "resolve extension before accept type" do
    @env.append_path(fixture_path_for_uri('resolve/javascripts'))
    @env.append_path(fixture_path_for_uri('resolve/stylesheets'))

    foo_js_uri  = "file://#{fixture_path_for_uri('resolve/javascripts/foo.js')}?type=application/javascript"
    foo_css_uri = "file://#{fixture_path_for_uri('resolve/stylesheets/foo.css')}?type=text/css"

    assert_equal foo_js_uri, resolve('foo.js', accept: 'application/javascript')
    assert_equal foo_css_uri, resolve('foo.css', accept: 'text/css')
    refute resolve('foo.js', accept: 'text/css')
    refute resolve('foo.css', accept: 'application/javascript')

    assert_equal foo_js_uri, resolve('foo.js', accept: '*/*')
    assert_equal foo_css_uri, resolve('foo.css', accept: '*/*')

    assert_equal foo_js_uri, resolve('foo.js', accept: 'text/css, */*')
    assert_equal foo_css_uri, resolve('foo.css', accept: 'application/javascript, */*')
  end

  test "resolve accept type quality in paths" do
    @env.append_path(fixture_path_for_uri('resolve/javascripts'))

    bar_js_uri  = "file://#{fixture_path_for_uri('resolve/javascripts/bar.js')}?type=application/javascript"
    bar_css_uri = "file://#{fixture_path_for_uri('resolve/javascripts/bar.css')}?type=text/css"

    assert_equal bar_js_uri, resolve('bar', accept: 'application/javascript')
    assert_equal bar_css_uri, resolve('bar', accept: 'text/css')

    assert_equal bar_js_uri, resolve('bar', accept: 'application/javascript, text/css')
    assert_equal bar_css_uri, resolve('bar', accept: 'text/css, application/javascript')

    assert_equal bar_css_uri, resolve('bar', accept: 'application/javascript; q=0.8, text/css')
    assert_equal bar_js_uri, resolve('bar', accept: 'text/css; q=0.8, application/javascript')

    assert_equal bar_js_uri, resolve('bar', accept: '*/*; q=0.8, application/javascript')
    assert_equal bar_css_uri, resolve('bar', accept: '*/*; q=0.8, text/css')
  end

  test "resolve with dependencies" do
    @env.append_path(fixture_path_for_uri('default'))

    uri, deps = @env.resolve("gallery.js", compat: false)
    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/gallery.js')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default')}"

    uri, deps = @env.resolve("coffee/foo.js", compat: false)
    assert_equal "file://#{fixture_path_for_uri('default/coffee/foo.coffee')}?type=application/javascript", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/coffee/foo.coffee')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/coffee')}"

    uri, deps = @env.resolve("manifest.js.yml", compat: false)
    assert_equal "file://#{fixture_path_for_uri('default/manifest.js.yml')}?type=text/yaml", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/manifest.js.yml')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default')}"

    uri, deps = @env.resolve("gallery", accept: 'application/javascript', compat: false)
    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/gallery.js')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default')}"
  end

  test "resolve under load path with dependencies" do
    @env.append_path(scripts = fixture_path_for_uri('resolve/javascripts'))
    @env.append_path(styles = fixture_path_for_uri('resolve/stylesheets'))

    uri, deps = @env.resolve('foo.js', load_paths: [scripts], compat: false)
    assert_equal "file://#{fixture_path_for_uri('resolve/javascripts/foo.js')}?type=application/javascript", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/javascripts/foo.js')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/javascripts')}"

    uri, deps = @env.resolve('foo.css', load_paths: [styles], compat: false)
    assert_equal "file://#{fixture_path_for_uri('resolve/stylesheets/foo.css')}?type=text/css", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/stylesheets/foo.css')}"
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/stylesheets')}"

    uri, deps = @env.resolve('foo.js', load_paths: [styles], compat: false)
    refute uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/stylesheets')}"

    uri, deps = @env.resolve('foo.css', load_paths: [scripts], compat: false)
    refute uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('resolve/javascripts')}"
  end

  test "resolve absolute with dependencies" do
    @env.append_path(fixture_path_for_uri('default'))

    uri, deps = @env.resolve(fixture_path_for_uri('default/gallery.js'), compat: false)
    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript", uri
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/gallery.js')}"
  end

  test "resolve uri identity with dependencies" do
    @env.append_path(fixture_path_for_uri('default'))

    uri1 = "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript"
    uri2, deps = @env.resolve(uri1, compat: false)
    assert_equal uri1, uri2
    assert_includes deps, "file-digest://#{fixture_path_for_uri('default/gallery.js')}"
  end

  test "resolve with pipeline" do
    @env.append_path(fixture_path_for_uri('default'))

    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript&pipeline=source",
      resolve("gallery.js", pipeline: :source)
    assert_equal "file://#{fixture_path_for_uri('default/coffee/foo.coffee')}?type=application/javascript&pipeline=source",
      resolve("coffee/foo.js", pipeline: :source)
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript&pipeline=source",
      resolve("jquery.tmpl.min", pipeline: :source)
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript&pipeline=source",
      resolve("jquery.tmpl.min.js", pipeline: :source)
    assert_equal "file://#{fixture_path_for_uri('default/manifest.js.yml')}?type=text/yaml&pipeline=source",
      resolve('manifest.js.yml', pipeline: :source)
    refute resolve("null", pipeline: :source)

    assert_equal "file://#{fixture_path_for_uri('default/gallery.js')}?type=application/javascript&pipeline=source",
      resolve("gallery.source.js")
    assert_equal "file://#{fixture_path_for_uri('default/coffee/foo.coffee')}?type=application/javascript&pipeline=source",
      resolve("coffee/foo.source.js")
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript&pipeline=source",
      resolve("jquery.tmpl.min.source")
    assert_equal "file://#{fixture_path_for_uri('default/jquery.tmpl.min.js')}?type=application/javascript&pipeline=source",
      resolve("jquery.tmpl.min.source.js")
    assert_equal "file://#{fixture_path_for_uri('default/manifest.js.yml')}?type=text/yaml&pipeline=source",
      resolve('manifest.js.source.yml')
  end

  test "verify all logical paths" do
    Dir.entries(Sprockets::TestCase::FIXTURE_ROOT).each do |dir|
      unless %w( . ..).include?(dir)
        @env.append_path(fixture_path_for_uri(dir))
      end
    end

    @env.logical_paths.each do |logical_path, filename|
      actual_path, _ = @env.parse_asset_uri(resolve(logical_path))
      assert_equal filename, actual_path,
        "Expected #{logical_path.inspect} to resolve to #{filename}"
    end
  end

  test "legacy logical path iterator with matchers" do
    @env.append_path(fixture_path_for_uri('default'))

    assert_equal ["application.js", "gallery.css"],
      @env.each_logical_path("application.js", /gallery\.css/).to_a
  end

  test "adds paths to exceptions" do
    random_path = SecureRandom.hex
    @env.append_path(random_path)

    error = assert_raises(Sprockets::FileNotFound) do
      uri, _ = @env.resolve!("thisfiledoesnotexistandshouldraiseerrors", {})
      uri
    end

    assert_match /#{ random_path }/, error.message
  end

  def resolve(path, options = {})
    uri, _ = @env.resolve(path, options.merge(compat: false))
    uri
  end
end
