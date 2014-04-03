require 'sprockets_test'
require 'sprockets/bower'

class TestBower < Sprockets::TestCase
  include Sprockets::Bower

  test "ignore path without bower.json" do
    assert_equal nil,
      expand_bower_path(fixture_path('default/gallery.js'), 'gallery.js')
  end

  test "expand bower.json main string" do
    assert_equal fixture_path('default/bower/main.js'),
      expand_bower_path(fixture_path('default/bower/bower.json'), 'bower.js')
  end

  test "expand bower.json main array" do
    assert_equal fixture_path('default/qunit/qunit.js'),
      expand_bower_path(fixture_path('default/qunit/bower.json'), '.js')
    assert_equal fixture_path('default/qunit/qunit.css'),
      expand_bower_path(fixture_path('default/qunit/bower.json'), '.css')
  end
end
