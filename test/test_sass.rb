require 'sprockets_test'
require 'shared_sass_tests'

silence_warnings do
  require 'sass'
end

class TestBaseSass < Sprockets::TestCase
  CACHE_PATH = File.expand_path("../../.sass-cache", __FILE__)

  def sass
    ::Sass
  end

  def sass_functions
    ::Sass::Script::Functions
  end

  def sass_engine
    ::Sass::Engine
  end

  def compressor
    Sprockets::SassCompressor
  end

  def teardown
    refute ::Sass::Script::Functions.instance_methods.include?(:asset_path)
    FileUtils.rm_r(CACHE_PATH) if File.exist?(CACHE_PATH)
    assert !File.exist?(CACHE_PATH)
  end
end

class TestNoSassFunctionSass < TestBaseSass
  module ::Sass::Script::Functions
    def javascript_path(path)
      ::Sass::Script::String.new("/js/#{path.value}", :string)
    end

    module Compass
      def stylesheet_path(path)
        ::Sass::Script::String.new("/css/#{path.value}", :string)
      end
    end
    include Compass
  end

  include SharedSassTestNoFunction
end

class TestSprocketsSass < TestBaseSass
  def setup
    super

    @env = Sprockets::Environment.new(".") do |env|
      env.cache = {}
      env.append_path(fixture_path('.'))
      env.append_path(fixture_path('compass'))
      env.append_path(fixture_path('octicons'))
    end
  end

  def teardown
    assert !File.exist?(CACHE_PATH)
  end

  def render(path)
    path = fixture_path(path)
    silence_warnings do
      @env.find_asset(path, accept: 'text/css').to_s
    end
  end

  test "raise sass error with line number" do
    begin
      ::Sass::Util.silence_sass_warnings do
        render('sass/error.sass')
      end
      flunk
    rescue Sass::SyntaxError => error
      assert error.message.include?("invalid")
      trace = error.backtrace[0]
      assert trace.include?("error.sass")
      assert trace.include?(":5")
    end
  end

  test "track sass dependencies metadata" do
    asset = nil
    silence_warnings do
      asset = @env.find_asset('sass/import_partial.css')
    end
    assert asset
    assert_equal [
      fixture_path('sass/_rounded.scss'),
      fixture_path('sass/import_partial.sass')
    ], asset.metadata[:sass_dependencies].to_a.sort
  end

  include SharedSassTestSprockets
end

class TestSassCompressor < TestBaseSass
  include SharedSassTestCompressor
end

class TestSassFunctions < TestSprocketsSass
  def setup
    super
    define_asset_path
  end

  def define_asset_path
    @env.context_class.class_eval do
      def asset_path(path, options = {})
        link_asset(path)
        "/#{path}"
      end
    end
  end

  include SharedSassTestFunctions
end
