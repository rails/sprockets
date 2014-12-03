require 'sprockets_test'

class TestRequire < Sprockets::TestCase
  ROOT = File.expand_path("../..", __FILE__)

  test "require individual library files" do
    Dir["#{ROOT}/lib/**/*.rb"].each do |fn|
      next if File.basename(fn) == "version.rb"

      system "ruby", fn
      assert $?.success?, "Failed to load #{fn.inspect}"
    end
  end
end
