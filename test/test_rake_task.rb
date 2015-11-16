require 'sprockets_test'

require 'rake/sprocketstask'
require 'rake'

class TestRakeTask < Sprockets::TestCase
  def setup
    @rake = Rake::Application.new
    Rake.application = @rake

    @env = Sprockets::Environment.new('.') do |env|
      env.append_path(fixture_path('default'))
    end

    @dir = File.join(Dir.tmpdir, 'sprockets/manifest')

    @manifest_custom_dir = Sprockets::Manifest.new(@env, @dir)

    @manifest_custom_path = Sprockets::Manifest.new(@env, @dir, File.join(@dir, 'manifest.json'))

    Rake::SprocketsTask.new do |t|
      t.environment = @env
      t.output      = @dir
      t.assets      = ['application.js']
      t.log_level   = :fatal
    end
  end

  def teardown
    Rake.application = nil

    # FileUtils.rm_rf(@dir)
    # wtf, dunno
    system "rm -rf #{@dir}"
    assert Dir["#{@dir}/*"].empty?
  end

  test 'assets' do
    digest_path = @env['application.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake[:assets].invoke

    assert Dir["#{@dir}/.sprockets-manifest-*.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  test 'clobber' do
    digest_path = @env['application.js'].digest_path

    @rake[:assets].invoke
    assert File.exist?("#{@dir}/#{digest_path}")

    @rake[:clobber_assets].invoke
    assert !File.exist?("#{@dir}/#{digest_path}")
  end

  test 'custom manifest directory' do
    Rake::SprocketsTask.new do |t|
      t.environment = nil
      t.manifest    = @manifest_custom_dir
      t.assets      = ['application.js']
      t.log_level   = :fatal
    end

    digest_path = @env['application.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake[:assets].invoke

    assert Dir["#{@dir}/.sprockets-manifest-*.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  test 'custom manifest path' do
    Rake::SprocketsTask.new do |t|
      t.environment = nil
      t.manifest    = @manifest_custom_path
      t.assets      = ['application.js']
      t.log_level   = :fatal
    end

    digest_path = @env['application.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake[:assets].invoke

    assert Dir["#{@dir}/manifest.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end

  test 'lazy custom manifest' do
    Rake::SprocketsTask.new do |t|
      t.environment = nil
      t.manifest    = -> { @manifest_custom_dir }
      t.assets      = ['application.js']
      t.log_level   = :fatal
    end

    digest_path = @env['application.js'].digest_path
    assert !File.exist?("#{@dir}/#{digest_path}")

    @rake[:assets].invoke

    assert Dir["#{@dir}/.sprockets-manifest-*.json"].first
    assert File.exist?("#{@dir}/#{digest_path}")
  end
end
