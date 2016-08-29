require 'sprockets_test'

class TestExporting < Sprockets::TestCase
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

  test 'reverse extension exporter' do
    @env.register_exporter 'application/javascript', ReverseExtensionExporter
    @env.register_exporter '*/*', DoubleExtensionExporter
    manifest = Sprockets::Manifest.new(@env, File.join(@dir, 'manifest.json'))
    manifest.compile('application.js')
    manifest.compile('blank.gif')

    application_asset = @env['application.js']
    blank_asset = @env['blank.gif']

    sj_path = "#{@dir}/#{application_asset.digest_path[0..-4]}.sj"
    jsjs_path = "#{@dir}/#{application_asset.digest_path}js"
    gnp_path = "#{@dir}/#{blank_asset.digest_path[0..-5]}.gnp"
    gifgif_path = "#{@dir}/#{blank_asset.digest_path}gif"

    assert File.exist?("#{sj_path}")
    assert !File.exist?("#{gnp_path}")
    assert File.exist?("#{jsjs_path}")
    assert File.exist?("#{gifgif_path}")

  end

end

class ReverseExtensionExporter
  def self.call(env, asset, target, dir, logger, wait)
    split = target.split('.')
    split[1] = split[1].reverse
    new_target = split.join('.')

    if File.exist?("#{new_target}")
      logger.debug "Skipping #{new_target}, already exists"
      return
    else
      logger.info "Writing #{new_target}"
      return Concurrent::Future.execute do
        wait.call
        asset.write_to new_target
      end
    end
  end
end

class DoubleExtensionExporter
  def self.call(env, asset, target, dir, logger, wait)
    split = target.split('.')
    new_target = target + split[1]

    if File.exist?("#{new_target}")
      logger.debug "Skipping #{new_target}, already exists"
      return
    else
      logger.info "Writing #{new_target}"
      return Concurrent::Future.execute do
        wait.call
        asset.write_to new_target
      end
    end
  end
end
