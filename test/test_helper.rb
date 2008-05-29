require File.join(File.dirname(__FILE__), *%w".. lib sprockets")
require "test/unit"

class Test::Unit::TestCase
  FIXTURES_PATH = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))
end
