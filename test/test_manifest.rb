require 'sprockets_test'
require 'fileutils'
require 'tmpdir'
require 'securerandom'

class TestManifest < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".") do |env|
      env.append_path(fixture_path('default'))
    end
    @dir = File.join(Dir::tmpdir, 'sprockets/manifest')
    FileUtils.mkdir_p(@dir)
  end

  def teardown
    # FileUtils.rm_rf(@dir)
    # wtf, dunno
    system "rm -rf #{@dir}"
    assert Dir["#{@dir}/*"].empty?
  end

  test "specify full manifest filename" do
    directory = Dir::tmpdir
    filename  = File.join(directory, 'manifest.json')

    manifest = Sprockets::Manifest.new(@env, filename)

    assert_equal directory, manifest.directory
    assert_equal filename, manifest.filename
    assert_equal filename, manifest.path
  end

  test "specify manifest directory yields random .sprockets-manifest-*.json" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    assert_equal @dir, manifest.directory
    assert_match(/^\.sprockets-manifest-[a-f0-9]{32}.json/, File.basename(manifest.filename))

    manifest.save
    assert_match(/^\.sprockets-manifest-[a-f0-9]{32}.json/, File.basename(manifest.filename))
  end

  test "specify manifest directory with existing legacy manifest-abc213.json" do
    path = File.join(@dir, "manifest-#{SecureRandom.hex(16)}.json")

    File.open(path, 'w') { |f| f.write "{}" }

    manifest = Sprockets::Manifest.new(@env, @dir)

    assert_equal @dir, manifest.directory
    assert_match(/^manifest-[a-f0-9]{32}.json/, File.basename(manifest.filename))

    manifest.save
    assert_match(/^\.sprockets-manifest-[a-f0-9]{32}.json/, File.basename(manifest.filename))
  end

  test "specify manifest directory with existing legacy manifest.json" do
    path = File.join(@dir, "manifest.json")

    File.open(path, 'w') { |f| f.write "{}" }

    manifest = Sprockets::Manifest.new(@env, @dir)

    assert_equal @dir, manifest.directory
    assert_equal "manifest.json", File.basename(manifest.filename)

    manifest.save
    assert_match(/^\.sprockets-manifest-[a-f0-9]{32}.json/, File.basename(manifest.filename))
  end

  test "specify manifest directory with existing .sprockets-manifest-*.json" do
    path = File.join(@dir, ".sprockets-manifest-#{SecureRandom.hex(16)}.json")
    File.open(path, 'w') { |f| f.write "{}" }

    assert File.exist?(path)
    manifest = Sprockets::Manifest.new(@env, @dir)

    assert_equal @dir, manifest.directory
    assert_equal path, manifest.filename
  end

  test "specify manifest directory and seperate location" do
    root  = File.join(Dir::tmpdir, 'public')
    dir   = File.join(root, 'assets')
    path  = File.join(root, 'manifest-123.json')

    system "rm -rf #{root}"
    assert !File.exist?(root)

    manifest = Sprockets::Manifest.new(@env, dir, path)

    assert_equal dir, manifest.directory
    assert_equal path, manifest.filename
  end

  test "compile asset" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    digest_path = @env['application.js'].digest_path

    assert !File.exist?("#{@dir}/#{digest_path}")

    manifest.compile('application.js')
    assert File.directory?(manifest.directory)
    assert File.file?(manifest.filename)

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][digest_path]
    assert_equal "application.js", data['files'][digest_path]['logical_path']
    assert data['files'][digest_path]['size'] > 230
    assert_equal digest_path, data['assets']['application.js']
  end

  test "compile to directory and seperate location" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    root  = File.join(Dir::tmpdir, 'public')
    dir   = File.join(root, 'assets')
    path  = File.join(root, 'manifests', 'manifest-123.json')

    system "rm -rf #{root}"
    assert !File.exist?(root)

    manifest = Sprockets::Manifest.new(@env, dir, path)

    manifest.compile('application.js')
    assert File.directory?(manifest.directory)
    assert File.file?(manifest.filename)
  end

  test "compile with legacy manifest" do
    root  = File.join(Dir::tmpdir, 'public')
    dir   = File.join(root, 'assets')
    path  = File.join(root, "manifest-#{SecureRandom.hex(16)}.json")

    system "rm -rf #{root}"
    assert !File.exist?(root)

    system "rm -rf #{dir}/.sprockets-manifest*.json"
    system "rm -rf #{dir}/manifest*.json"
    FileUtils.mkdir_p(dir)
    File.open(path, 'w') { |f| f.write "{}" }

    manifest = Sprockets::Manifest.new(@env, dir)

    manifest.compile('application.js')
    assert File.directory?(manifest.directory)
    assert File.file?(manifest.filename)
    assert_match %r{.sprockets-manifest-[a-f0-9]{32}.json}, manifest.filename
  end

  test "compile asset with absolute path" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    digest_path = @env['application.js'].digest_path

    assert !File.exist?("#{@dir}/#{digest_path}")

    manifest.compile(fixture_path('default/application.js.coffee'))

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][digest_path]
    assert_equal digest_path, data['assets']['application.js']
  end

  test "compile multiple assets" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    app_digest_path = @env['application.js'].digest_path
    gallery_digest_path = @env['gallery.css'].digest_path

    assert !File.exist?("#{@dir}/#{app_digest_path}")
    assert !File.exist?("#{@dir}/#{gallery_digest_path}")

    manifest.compile('application.js', 'gallery.css')

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{app_digest_path}")
    assert File.exist?("#{@dir}/#{gallery_digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][app_digest_path]
    assert data['files'][gallery_digest_path]
    assert_equal app_digest_path, data['assets']['application.js']
    assert_equal gallery_digest_path, data['assets']['gallery.css']
  end

  test "compile with transformed asset" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    assert svg_digest_path = @env['logo.svg'].digest_path
    assert png_digest_path = @env['logo.png'].digest_path

    assert !File.exist?("#{@dir}/#{svg_digest_path}")
    assert !File.exist?("#{@dir}/#{png_digest_path}")

    manifest.compile('logo.svg', 'logo.png')

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{svg_digest_path}")
    assert File.exist?("#{@dir}/#{png_digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][svg_digest_path]
    assert data['files'][png_digest_path]
    assert_equal svg_digest_path, data['assets']['logo.svg']
    assert_equal png_digest_path, data['assets']['logo.png']
  end

  test "compile asset with links" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    main_digest_path = @env['gallery-link.js'].digest_path
    dep_digest_path  = @env['gallery.js'].digest_path

    assert !File.exist?("#{@dir}/#{main_digest_path}")
    assert !File.exist?("#{@dir}/#{dep_digest_path}")

    manifest.compile('gallery-link.js')
    assert File.directory?(manifest.directory)
    assert File.file?(manifest.filename)

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{main_digest_path}")
    assert File.exist?("#{@dir}/#{dep_digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][main_digest_path]
    assert data['files'][dep_digest_path]
    assert_equal "gallery-link.js", data['files'][main_digest_path]['logical_path']
    assert_equal "gallery.js", data['files'][dep_digest_path]['logical_path']
    assert_equal main_digest_path, data['assets']['gallery-link.js']
    assert_equal dep_digest_path, data['assets']['gallery.js']
  end

  test "compile nested asset with links" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    main_digest_path   = @env['explore-link.js'].digest_path
    dep_digest_path    = @env['gallery-link.js'].digest_path
    subdep_digest_path = @env['gallery.js'].digest_path

    assert !File.exist?("#{@dir}/#{main_digest_path}")
    assert !File.exist?("#{@dir}/#{dep_digest_path}")
    assert !File.exist?("#{@dir}/#{subdep_digest_path}")

    manifest.compile('explore-link.js')
    assert File.directory?(manifest.directory)
    assert File.file?(manifest.filename)

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{main_digest_path}")
    assert File.exist?("#{@dir}/#{dep_digest_path}")
    assert File.exist?("#{@dir}/#{subdep_digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][main_digest_path]
    assert data['files'][dep_digest_path]
    assert data['files'][subdep_digest_path]
    assert_equal "explore-link.js", data['files'][main_digest_path]['logical_path']
    assert_equal "gallery-link.js", data['files'][dep_digest_path]['logical_path']
    assert_equal "gallery.js", data['files'][subdep_digest_path]['logical_path']
    assert_equal main_digest_path, data['assets']['explore-link.js']
    assert_equal dep_digest_path, data['assets']['gallery-link.js']
    assert_equal subdep_digest_path, data['assets']['gallery.js']
  end

  test "compile index asset" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    digest_path = @env['coffee.js'].digest_path
    assert_match(/coffee\/index-\w+.js/, digest_path)

    assert !File.exist?("#{@dir}/#{digest_path}")

    manifest.compile('coffee.js')

    assert File.exist?("#{@dir}/#{digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][digest_path]
    assert_equal "coffee/index.js", data['files'][digest_path]['logical_path']
    assert_equal digest_path, data['assets']['coffee/index.js']
    assert_equal digest_path, data['assets']['coffee.js']
  end

  test "compile with regex" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    app_digest_path = @env['application.js'].digest_path
    gallery_digest_path = @env['gallery.css'].digest_path

    assert !File.exist?("#{@dir}/#{app_digest_path}")
    assert !File.exist?("#{@dir}/#{gallery_digest_path}")

    manifest.compile('gallery.css', /application.js/)

    assert File.exist?("#{@dir}/manifest.json")
    assert File.exist?("#{@dir}/#{app_digest_path}")
    assert File.exist?("#{@dir}/#{gallery_digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][app_digest_path]
    assert data['files'][gallery_digest_path]
    assert_equal app_digest_path, data['assets']['application.js']
    assert_equal gallery_digest_path, data['assets']['gallery.css']
  end

  test "recompile asset" do
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))

    digest_path = @env['application.js'].digest_path
    filename = fixture_path('default/application.js.coffee')

    sandbox filename do
      assert !File.exist?("#{@dir}/#{digest_path}"), Dir["#{@dir}/*"].inspect

      manifest.compile('application.js')

      assert File.exist?("#{@dir}/manifest.json")
      assert File.exist?("#{@dir}/#{digest_path}")

      data = JSON.parse(File.read(manifest.filename))
      assert data['files'][digest_path]
      assert_equal digest_path, data['assets']['application.js']

      File.open(filename, 'w') { |f| f.write "change;" }
      mtime = Time.now + 1
      File.utime(mtime, mtime, filename)
      new_digest_path = @env['application.js'].digest_path

      manifest.compile('application.js')

      assert File.exist?("#{@dir}/manifest.json")
      assert File.exist?("#{@dir}/#{digest_path}")
      assert File.exist?("#{@dir}/#{new_digest_path}")

      data = JSON.parse(File.read(manifest.filename))
      assert data['files'][digest_path]
      assert data['files'][new_digest_path]
      assert_equal new_digest_path, data['assets']['application.js']
    end
  end

  test "remove asset" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    digest_path = @env['application.js'].digest_path

    manifest.compile('application.js')
    assert File.exist?("#{@dir}/#{digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert data['files'][digest_path]
    assert data['assets']['application.js']

    manifest.remove(digest_path)

    assert !File.exist?("#{@dir}/#{digest_path}")

    data = JSON.parse(File.read(manifest.filename))
    assert !data['files'][digest_path]
    assert !data['assets']['application.js']
  end

  test "remove old asset" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    digest_path = @env['application.js'].digest_path
    filename = fixture_path('default/application.js.coffee')

    sandbox filename do
      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{digest_path}")

      File.open(filename, 'w') { |f| f.write "change;" }
      mtime = Time.now + 1
      File.utime(mtime, mtime, filename)
      new_digest_path = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path}")

      manifest.remove(digest_path)
      assert !File.exist?("#{@dir}/#{digest_path}")

      data = JSON.parse(File.read(manifest.filename))
      assert !data['files'][digest_path]
      assert data['files'][new_digest_path]
      assert_equal new_digest_path, data['assets']['application.js']
    end
  end

  test "remove old backups(count)" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    digest_path = @env['application.js'].digest_path
    filename = fixture_path('default/application.js.coffee')

    sandbox filename do
      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{digest_path}")

      File.open(filename, 'w') { |f| f.write "a;" }
      mtime = Time.now + 1
      File.utime(mtime, mtime, filename)
      new_digest_path1 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path1}")

      File.open(filename, 'w') { |f| f.write "b;" }
      mtime = Time.now + 2
      File.utime(mtime, mtime, filename)
      new_digest_path2 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path2}")

      File.open(filename, 'w') { |f| f.write "c;" }
      mtime = Time.now + 3
      File.utime(mtime, mtime, filename)
      new_digest_path3 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path3}")

      manifest.clean(1, 0)

      assert !File.exist?("#{@dir}/#{digest_path}")
      assert !File.exist?("#{@dir}/#{new_digest_path1}")
      assert File.exist?("#{@dir}/#{new_digest_path2}")
      assert File.exist?("#{@dir}/#{new_digest_path3}")

      data = JSON.parse(File.read(manifest.filename))
      assert !data['files'][digest_path]
      assert !data['files'][new_digest_path1]
      assert data['files'][new_digest_path2]
      assert data['files'][new_digest_path3]
      assert_equal new_digest_path3, data['assets']['application.js']
    end
  end

  test "remove old backups(age)" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    filename = fixture_path('default/application.js.coffee')

    sandbox filename do

      File.open(filename, 'w') { |f| f.write "a;" }
      mtime = Time.local(2014, 4, 26, 12, 0, 0)
      File.utime(mtime, mtime, filename)
      new_digest_path1 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path1}")

      File.open(filename, 'w') { |f| f.write "b;" }
      mtime = Time.local(2014, 4, 27, 8, 0, 0)
      File.utime(mtime, mtime, filename)
      new_digest_path2 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path2}")

      File.open(filename, 'w') { |f| f.write "c;" }
      mtime = Time.local(2014, 4, 27, 9, 0, 0)
      File.utime(mtime, mtime, filename)
      new_digest_path3 = @env['application.js'].digest_path

      manifest.compile('application.js')
      assert File.exist?("#{@dir}/#{new_digest_path3}")

      Time.stub(:now, Time.local(2014, 4, 27, 12, 0, 0)) do
        manifest.clean(0, 60 * 60 * 24)
      end

      assert !File.exist?("#{@dir}/#{new_digest_path1}")
      assert File.exist?("#{@dir}/#{new_digest_path2}")
      assert File.exist?("#{@dir}/#{new_digest_path3}")

      data = JSON.parse(File.read(manifest.filename))
      assert !data['files'][new_digest_path1]
      assert data['files'][new_digest_path2]
      assert data['files'][new_digest_path3]
      assert_equal new_digest_path3, data['assets']['application.js']
    end
  end

  test "test manifest does not exist" do
    assert !File.exist?("#{@dir}/manifest.json")

    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))
    manifest.compile('application.js')

    assert File.exist?("#{@dir}/manifest.json")
    data = JSON.parse(File.read(manifest.filename))
    assert data['assets']['application.js']
  end

  test "test blank manifest" do
    assert !File.exist?("#{@dir}/manifest.json")

    FileUtils.mkdir_p(@dir)
    File.open("#{@dir}/manifest.json", 'w') { |f| f.write "" }
    assert_equal "", File.read("#{@dir}/manifest.json")

    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))
    manifest.compile('application.js')

    assert File.exist?("#{@dir}/manifest.json")
    data = JSON.parse(File.read(manifest.filename))
    assert data['assets']['application.js']
  end

  test "test skip invalid manifest" do
    assert !File.exist?("#{@dir}/manifest.json")

    FileUtils.mkdir_p(@dir)
    File.open("#{@dir}/manifest.json", 'w') { |f| f.write "not valid json;" }
    assert_equal "not valid json;", File.read("#{@dir}/manifest.json")

    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))
    manifest.compile('application.js')

    assert File.exist?("#{@dir}/manifest.json")
    data = JSON.parse(File.read(manifest.filename))
    assert data['assets']['application.js']
  end

  test "nil environment raises compilation error" do
    assert !File.exist?("#{@dir}/manifest.json")

    manifest = Sprockets::Manifest.new(nil, File.join(@dir, 'manifest.json'))
    assert_raises Sprockets::Error do
      manifest.compile('application.js')
    end
  end

  test "no environment raises compilation error" do
    assert !File.exist?("#{@dir}/manifest.json")

    manifest = Sprockets::Manifest.new(File.join(@dir, 'manifest.json'))
    assert_raises Sprockets::Error do
      manifest.compile('application.js')
    end
  end

  test "find all filenames matching fnmatch filters" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    manifest.find("mobile/*.js").each do |asset|
      paths << asset.logical_path
    end

    assert paths.include?("mobile/a.js")
    assert paths.include?("mobile/b.js")
    assert !paths.include?("mobile/c.css")
  end

  test "iterate over each logical path matches index files" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    manifest.find("coffee.js").each do |asset|
      paths << asset.logical_path
    end
    assert paths.include?("coffee/index.js")
    assert !paths.include?("coffee.js")
  end

  test "each logical path enumerator matching fnmatch filters" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    enum = manifest.find("mobile/*.js")
    enum.to_a.each do |asset|
      paths << asset.logical_path
    end

    assert paths.include?("mobile/a.js")
    assert paths.include?("mobile/b.js")
    assert !paths.include?("mobile/c.css")
  end

  test "iterate over each logical path matching regexp filters" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    manifest.find(/mobile\/.*\.js/).each do |asset|
      paths << asset.logical_path
    end

    assert paths.include?("mobile/a.js")
    assert paths.include?("mobile/b.js")
    assert !paths.include?("mobile/c.css")
  end

  test "iterate over each logical path matching proc filters" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    manifest.find(proc { |fn| fn.match("mobile/") && File.extname(fn) == '.js' }).each do |asset|
      paths << asset.logical_path
    end

    assert paths.include?("mobile/a.js")
    assert paths.include?("mobile/b.js")
    assert !paths.include?("mobile/c.css")
  end

  test "iterate over each logical path matching proc filters with full path arg" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    paths = []
    manifest.find(proc { |_, fn| fn.match(fixture_path('default/mobile')) }).each do |asset|
      paths << asset.logical_path
    end

    assert paths.include?("mobile/a.js")
    assert paths.include?("mobile/b.js")
    assert !paths.include?("application.js")
  end

  test "find_sources with environment" do
    manifest = Sprockets::Manifest.new(@env, @dir)

    result = manifest.find_sources("mobile/a.js", "mobile/b.js")
    assert_equal ["var A;\n", "var B;\n"], result.to_a.sort

    result = manifest.find_sources("not_existent.js", "also_not_existent.js")
    assert_equal [], result.to_a

    result = manifest.find_sources("mobile/a.js", "also_not_existent.js")
    assert_equal ["var A;\n"], result.to_a
  end

  test "find_sources without environment" do
    manifest = Sprockets::Manifest.new(@env, @dir)
    manifest.compile('mobile/a.js', 'mobile/b.js')

    manifest = Sprockets::Manifest.new(nil, @dir)

    result = manifest.find_sources("mobile/a.js", "mobile/b.js")
    assert_equal ["var A;\n", "var B;\n"], result.to_a

    result = manifest.find_sources("not_existent.js", "also_not_existent.js")
    assert_equal [], result.to_a

    result = manifest.find_sources("mobile/a.js", "also_not_existent.js")
    assert_equal ["var A;\n"], result.to_a
  end

  test "compress non-binary assets" do
    manifest = Sprockets::Manifest.new(@env, @dir)
    %W{ gallery.css application.js logo.svg favicon.ico }.each do |file_name|
      original_path = @env[file_name].digest_path
      manifest.compile(file_name)
      assert File.exist?("#{@dir}/#{original_path}.gz"), "Expecting '#{original_path}' to generate gzipped file: '#{original_path}.gz' but it did not"
      assert_equal File.stat("#{@dir}/#{original_path}").mtime, Zlib::GzipReader.open("#{@dir}/#{original_path}.gz") {|gz| gz.mtime }
    end
  end

  test "writes gzip files even if files were already on disk" do
    @env.gzip = false
    manifest = Sprockets::Manifest.new(@env, @dir)
    files = %W{ gallery.css application.js logo.svg favicon.ico}
    files.each do |file_name|
      original_path = @env[file_name].digest_path
      manifest.compile(file_name)
      assert File.exist?("#{@dir}/#{original_path}"), "Expecting \"#{@dir}/#{original_path}\" to exist but did not"
    end

    @env.gzip = true
    files.each do |file_name|
      original_path = @env[file_name].digest_path
      manifest.compile(file_name)
      assert File.exist?("#{@dir}/#{original_path}.gz"), "Expecting '#{original_path}' to generate gzipped file: '#{original_path}.gz' but it did not"
      assert_equal File.stat("#{@dir}/#{original_path}").mtime, Zlib::GzipReader.open("#{@dir}/#{original_path}.gz") {|gz| gz.mtime }
    end
  end

  test "disable file gzip" do
    @env.gzip = false
    manifest = Sprockets::Manifest.new(@env, @dir)
    %W{ gallery.css application.js logo.svg favicon.ico }.each do |file_name|
      original_path = @env[file_name].digest_path
      manifest.compile(file_name)
      refute File.exist?("#{@dir}/#{original_path}.gz"), "Expecting '#{original_path}' to not generate gzipped file: '#{original_path}.gz' but it did"
    end
  end

  test "do not compress binary assets" do
    manifest = Sprockets::Manifest.new(@env, @dir)
    %W{ blank.gif }.each do |file_name|
      original_path = @env[file_name].digest_path
      manifest.compile(file_name)
      refute File.exist?("#{@dir}/#{original_path}.gz"), "Expecting '#{original_path}' to not generate gzipped file: '#{original_path}.gz' but it did"
    end
  end

  test 'raises exception when gzip fails' do
    manifest = Sprockets::Manifest.new(@env, @dir)
    Zlib::GzipWriter.stub(:new, -> { fail 'kaboom' }) do
      assert_raises('kaboom') { manifest.compile('application.js') }
    end
  end
end
