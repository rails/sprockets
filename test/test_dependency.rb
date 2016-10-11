# frozen_string_literal: true
require "sprockets_test"

class DependencyTest < Sprockets::TestCase
  def setup
    @old_env_value = ENV['DEPENDENCY_TEST_VALUE']
    ENV['DEPENDENCY_TEST_VALUE'] = 'Hello'
    @env = Sprockets::Environment.new
  end

  def teardown
    ENV['DEPENDENCY_TEST_VALUE'] = @old_env_value
  end

  def test_env_dependency
    assert_equal @env.resolve_dependency('env:DEPENDENCY_TEST_VALUE'), 'Hello'
    assert_nil @env.resolve_dependency('env:NONEXISTANT_DEPENDENCY_TEST_VALUE')
  end
end
