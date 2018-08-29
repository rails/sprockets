# frozen_string_literal: true
require 'minitest/autorun'

class TestRequire < MiniTest::Test
  parallelize_me!

  ROOT = File.expand_path("../..", __FILE__)

  Dir["#{ROOT}/lib/**/*.rb"].each do |fn|
    basename = File.basename(fn)
    next if basename == "version.rb"
    next if RUBY_PLATFORM.include?('java') && ['zopfli.rb', 'jsminc.rb', 'sassc.rb'].include?(basename)

    define_method "test_require_individual_library_files: #{fn}" do
      system "ruby", "-I#{ROOT}/lib", fn
      assert $?.success?, "Failed to load #{fn.inspect}"
    end
  end
end
