require 'sprockets_test'

class TestRequire < Sprockets::TestCase
  parallelize_me!

  ROOT = File.expand_path("../..", __FILE__)

  Dir["#{ROOT}/lib/**/*.rb"].each do |fn|
    next if File.basename(fn) == "version.rb"

    test "require individual library files #{fn}" do
      system "ruby", fn
      assert $?.success?, "Failed to load #{fn.inspect}"
    end
  end
end
