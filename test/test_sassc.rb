# frozen_string_literal: true
require 'sprockets_test'
require 'shared_sass_tests'

silence_warnings do
  require 'sassc'
end

require 'sprockets/sassc_processor'
require 'sprockets/sassc_compressor'

class TestBaseSassc < Sprockets::TestCase
  CACHE_PATH = File.expand_path("../../.sass-cache", __FILE__)

  def sass
    ::SassC
  end

  def sass_functions
    ::SassC::Script::Functions
  end

  def sass_engine
    ::SassC::Engine
  end

  def syntax_error
    SassC::SyntaxError
  end

  def compressor
    Sprockets::SasscCompressor
  end

  def teardown
    refute ::SassC::Script::Functions.instance_methods.include?(:asset_path)
    FileUtils.rm_r(CACHE_PATH) if File.exist?(CACHE_PATH)
    assert !File.exist?(CACHE_PATH)
  end
end

class TestNoSassFunctionSassC < TestBaseSassc
  module ::SassC::Script::Functions
    def javascript_path(path)
      ::SassC::Script::Value::String.new("/js/#{path.value}", :string)
    end

    module Compass
      def stylesheet_path(path)
        ::SassC::Script::Value::String.new("/css/#{path.value}", :string)
      end
    end
    include Compass
  end

  include SharedSassTestNoFunction
end

class TestSprocketsSassc < TestBaseSassc
  def setup
    super

    @env = Sprockets::Environment.new(".") do |env|
      env.cache = {}
      env.append_path(fixture_path('.'))
      env.append_path(fixture_path('compass'))
      env.append_path(fixture_path('octicons'))
      env.register_transformer 'text/sass', 'text/css', Sprockets::SasscProcessor.new
      env.register_transformer 'text/scss', 'text/css', Sprockets::ScsscProcessor.new
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
      render('sass/error.sass')
      flunk
    rescue SassC::SyntaxError => error
      # this is not exactly consistent with ruby sass
      assert error.message.include?("invalid")
      assert error.message.include?("error.sass")
      assert error.message.include?("line 5")
    end
  end

  test "track sass dependencies metadata" do
    skip "not consistent with ruby sass"

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

class TestSasscCompressor < TestBaseSassc
  include SharedSassTestCompressor
end

class TestSasscFunctions < TestSprocketsSassc
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
