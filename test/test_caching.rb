require 'sprockets_test'

class TestCaching < Sprockets::TestCase
  def setup
    @cache = {}

    @env1 = Sprockets::Environment.new(fixture_path('default')) do |env|
      env.append_path(".")
      env.cache = @cache
    end

    @env2 = Sprockets::Environment.new(fixture_path('symlink')) do |env|
      env.append_path(".")
      env.cache = @cache
    end
  end

  test "environment digests are the same for different roots" do
    assert_equal @env1.digest, @env2.digest
  end

  test "shared cache objects are eql" do
    asset1 = @env1['gallery.js']
    asset2 = @env2['gallery.js']

    assert asset1
    assert asset2

    assert asset1.eql?(asset2)
    assert asset2.eql?(asset1)
    assert !asset1.equal?(asset2)
  end
end
