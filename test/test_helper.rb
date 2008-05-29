require File.join(File.dirname(__FILE__), *%w".. lib sprockets")
require "test/unit"

class Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "fixtures")) unless defined?(FIXTURES_PATH)
  
  protected
    def environment_for_fixtures
      Sprockets::Environment.new(FIXTURES_PATH, source_directories_in_fixtures_path)
    end
  
    def source_directories_in_fixtures_path
      Dir[File.join(FIXTURES_PATH, "**", "src")]
    end

    def assert_absolute_location(location, pathname)
      assert_equal location, pathname.absolute_location
    end
    
    def assert_absolute_location_ends_with(location_ending, pathname)
      assert pathname.absolute_location[/#{Regexp.escape(location_ending)}$/]
    end
end
