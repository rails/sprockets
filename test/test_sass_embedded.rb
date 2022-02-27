# frozen_string_literal: true
require 'sprockets_test'
require 'shared_sass_embedded_tests'

require 'sass'

# Silent all sass compiler warnings during tests
::Sass.module_eval {
  [:compile, :compile_string].each do |symbol|
    original_method = singleton_method(symbol)
    silent_method = lambda do |source, **kwargs|
      kwargs[:logger] = ::Sass::Logger.silent
      original_method.call(source, **kwargs)
    end
    define_singleton_method symbol, silent_method
  end
}

require 'sprockets/sass_processor'
require 'sprockets/sass_compressor'

class TestBaseSass < Sprockets::TestCase
  CACHE_PATH = File.expand_path("../../.sass-cache", __FILE__)

  def sass
    ::Sass
  end

  def sass_functions
    ::Sass::Script::Functions
  end

  def processor
    Sprockets::SassProcessor
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
      ::Sass::Value::String.new("/js/#{path.text}", quoted: true)
    end

    module Compass
      def stylesheet_path(path)
        ::Sass::Value::String.new("/css/#{path.text}", quoted: true)
      end
    end
    include Compass
  end

  include SharedSassEmbeddedTestNoFunction
end

class TestSprocketsSass < TestBaseSass
  def setup
    super

    @env = Sprockets::Environment.new(".") do |env|
      env.cache = {}
      env.append_path(fixture_path('.'))
      env.append_path(fixture_path('compass'))
      env.append_path(fixture_path('octicons'))
      env.register_transformer 'text/sass', 'text/css', Sprockets::SassProcessor.new
      env.register_transformer 'text/scss', 'text/css', Sprockets::ScssProcessor.new
    end
  end

  def teardown
    assert !File.exist?(CACHE_PATH)
  end

  def render(path)
    path = fixture_path(path)
    @env.find_asset(path, accept: 'text/css').to_s
  end

  test "raise sass error with line number" do
    skip 'In dart sass this prints a warning instead of throwing error'
    begin
      render('sass/error.sass')
      flunk
    rescue Sass::CompileError => error
      assert error.message.include?("invalid")
      trace = error.backtrace[0]
      assert trace.include?("error.sass")
      assert trace.include?(":5")
    end
  end

  test "track sass dependencies metadata" do
    asset = nil
    asset = @env.find_asset('sass/import_partial.css')
    assert asset
    assert_equal [
      fixture_path('sass/_rounded.scss'),
      fixture_path('sass/import_partial.sass')
    ], asset.metadata[:sass_dependencies].to_a.sort
  end

  include SharedSassEmbeddedTestSprockets
end

class TestSassEmbeddedCompressor < TestBaseSass
  include SharedSassEmbeddedTestCompressor
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

  include SharedSassEmbeddedTestFunctions
end
