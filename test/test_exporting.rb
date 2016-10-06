require 'sprockets_test'

class TestExporting < Sprockets::TestCase
  def setup
    @dir = Dir.mktmpdir
    FileUtils.mkdir_p(@dir)

    @env = Sprockets::Environment.new(".") do |env|
      env.append_path(fixture_path('default'))
    end
    @manifest = Sprockets::Manifest.new(@env, @dir)
  end

  def teardown
    FileUtils.remove_entry_secure(@dir) if File.exist?(@dir)
    assert Dir["#{@dir}/*"].empty?
  end

  test 'extension exporters' do
    @env.register_exporter 'application/javascript', ReverseExtensionExporter
    @env.register_exporter '*/*', DoubleExtensionExporter

    @manifest.compile('application.js')
    @manifest.compile('blank.gif')

    js_path  = @env['application.js'].digest_path
    gif_path = @env['blank.gif'].digest_path

    reverse_js_path  = "#{@dir}/#{js_path[0..-4]}.sj"
    double_js_path   = "#{@dir}/#{js_path}js"
    reverse_gif_path = "#{@dir}/#{gif_path[0..-5]}.fig"
    double_gif_path  = "#{@dir}/#{gif_path}gif"

    assert File.exist?(reverse_js_path),   "Expected #{reverse_js_path} to exist, but it didn't"
    assert !File.exist?(reverse_gif_path), "Expected #{reverse_gif_path} to not exist, but it didn't"
    assert File.exist?(double_js_path),    "Expected #{double_js_path} to exist, but it didn't"
    assert File.exist?(double_gif_path),   "Expected #{double_gif_path} to exist, but it didn't"
  end

  test 'unregistering exporter without mime type' do
    @env.register_exporter '*/*', DoubleExtensionExporter
    @env.unregister_exporter DoubleExtensionExporter

    @manifest.compile('application.js')

    js_path = @env['application.js'].digest_path
    double_js_path = "#{@dir}/#{js_path}js"

    assert !File.exist?(double_js_path)
  end

  test 'unregistering exporter with mime type' do
    @env.register_exporter 'application/javascript', DoubleExtensionExporter
    @env.unregister_exporter 'application/javascript', DoubleExtensionExporter

    @manifest.compile('application.js')

    js_path = @env['application.js'].digest_path
    double_js_path = "#{@dir}/#{js_path}js"

    assert !File.exist?(double_js_path)
  end

  test 'unregistering exporter with multiple mime types' do
    @env.register_exporter %w(application/javascript image/gif), ReverseExtensionExporter
    @env.unregister_exporter %w(application/javascript image/gif), ReverseExtensionExporter

    @manifest.compile('application.js')
    @manifest.compile('blank.gif')

    js_path  = @env['application.js'].digest_path
    gif_path = @env['blank.gif'].digest_path

    reverse_js_path  = "#{@dir}/#{js_path[0..-4]}.sj"
    double_js_path   = "#{@dir}/#{js_path}js"
    reverse_gif_path = "#{@dir}/#{gif_path[0..-5]}.fig"
    double_gif_path  = "#{@dir}/#{gif_path}gif"

    assert !File.exist?(reverse_js_path),  "Expected #{ reverse_js_path } to not exist, but it did"
    assert !File.exist?(reverse_gif_path), "Expected #{ reverse_gif_path } to not exist, but it did"
    assert !File.exist?(double_js_path),   "Expected #{ double_js_path } to not exist, but it did"
    assert !File.exist?(double_gif_path),  "Expected #{ double_gif_path } to not exist, but it did"
  end
end

class ReverseExtensionExporter < Sprockets::Exporters::Base
  def call
    split      = target.split('.')
    split[1]   = split[1].reverse
    new_target = split.join('.')

    write(new_target) do |f|
      f.write(asset.source)
    end
    return new_target
  end
end

class DoubleExtensionExporter < Sprockets::Exporters::Base
  def call
    split = target.split('.')
    new_target = target + split[1]

    write(new_target) do |f|
      f.write(asset.source)
    end
    return new_target
  end
end
