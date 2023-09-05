# frozen_string_literal: true
require 'minitest/autorun'
require 'sprockets'
require 'sprockets/cache'
require 'sprockets/erb_processor'
require 'sass'

class TestERBProcessor < Minitest::Test

  def uri_path(path)
    path = '/' + path if path[1] == ':' # Windows path / drive letter
    path
  end

  def test_compile_js_erb_template
    environment = Sprockets::Environment.new

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "var data = <%= JSON.generate({foo: true}) %>;",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = "var data = {\"foo\":true};"
    assert_equal output, Sprockets::ERBProcessor.call(input)[:data]
  end

  def test_compile_erb_template_that_depends_on_env
    old_env_value = ::ENV['ERB_ENV_TEST_VALUE']
    ::ENV['ERB_ENV_TEST_VALUE'] = 'success'

    if RUBY_ENGINE == 'truffleruby' and Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('23.0.0.a')
      skip 'https://github.com/oracle/truffleruby/issues/2810'
    end

    root = File.expand_path("../fixtures", __FILE__)
    environment = Sprockets::Environment.new(root)
    environment.append_path 'default'

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "<%= ENV['ERB_ENV_TEST_VALUE'] %>;",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = "success;"
    result = Sprockets::ERBProcessor.call(input)
    assert_equal output, result[:data]
    assert_equal "env:ERB_ENV_TEST_VALUE", result[:dependencies].first
  ensure
    ::ENV['ERB_ENV_TEST_VALUE'] = old_env_value
  end

  def test_compile_erb_template_that_depends_on_empty_env
    old_env_value = ::ENV.delete('ERB_ENV_TEST_VALUE')

    if RUBY_ENGINE == 'truffleruby' and Gem::Version.new(RUBY_ENGINE_VERSION) < Gem::Version.new('23.0.0.a')
      skip 'https://github.com/oracle/truffleruby/issues/2810'
    end

    root = File.expand_path("../fixtures", __FILE__)
    environment = Sprockets::Environment.new(root)
    environment.append_path 'default'

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "<%= ENV['ERB_ENV_TEST_VALUE'] %>;",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = ";"
    result = Sprockets::ERBProcessor.call(input)
    assert_equal output, result[:data]
    assert_equal "env:ERB_ENV_TEST_VALUE", result[:dependencies].first
  ensure
    ::ENV['ERB_ENV_TEST_VALUE'] = old_env_value
  end

  def test_compile_erb_template_with_depend_on_call
    root = File.expand_path("../fixtures", __FILE__)
    environment = Sprockets::Environment.new(root)
    environment.append_path 'default'

    path = "#{root}/default/gallery.js"
    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "<%= depend_on('#{path}') %>\nvar data = 'DATA';",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = "var data = 'DATA';"
    result = Sprockets::ERBProcessor.call(input)
    assert_equal output, result[:data]
    assert_equal "file-digest://#{uri_path(path)}", result[:dependencies].first
  end

  def test_compile_erb_template_with_depend_on_call_outside_load_paths
    root = File.expand_path("../fixtures", __FILE__)
    environment = Sprockets::Environment.new(root)
    environment.append_path 'default'

    path = "#{root}/asset/application.js"
    assert File.exist?(path)

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "<%= depend_on('#{path}') %>\nvar data = 'DATA';",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = "var data = 'DATA';"
    result = Sprockets::ERBProcessor.call(input)
    assert_equal output, result[:data]
    assert_equal "file-digest://#{uri_path(path)}", result[:dependencies].first
  end

  def test_pass_custom_erb_helpers_to_template
    environment = Sprockets::Environment.new

    template = Sprockets::ERBProcessor.new do
      def foo
        :bar
      end
    end

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "var foo = <%= foo %>;",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    output = "var foo = bar;"
    assert_equal output, template.call(input)[:data]
  end

  def test_compile_js_erb_template_with_top_level_constant_access
    environment = Sprockets::Environment.new

    Sprockets.const_set(:Sass, Class.new)

    input = {
      environment: environment,
      filename: "foo.js.erb",
      content_type: 'application/javascript',
      data: "var sass_version = '<%= Sass::VERSION %>';",
      metadata: {},
      cache: Sprockets::Cache.new
    }

    assert_match(/sass_version/, Sprockets::ERBProcessor.call(input)[:data])
  ensure
    Sprockets.send(:remove_const, :Sass)
  end
end
