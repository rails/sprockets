require 'minitest/autorun'

class TestRequire < MiniTest::Test
  parallelize_me!

  ROOT = File.expand_path("../..", __FILE__)

  Dir["#{ROOT}/lib/**/*.rb"].each do |fn|
    next if File.basename(fn) == "version.rb"

    define_method "test_require_individual_library_files: #{fn}" do
      system "ruby", fn
      assert $?.success?, "Failed to load #{fn.inspect}"
    end
  end
end
