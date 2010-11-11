require "test/unit"
require "sprockets"

class Sprockets::TestCase < Test::Unit::TestCase
  FIXTURE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "fixtures"))

  undef_method :default_test

  def self.test(name, &block)
    define_method("test #{name.inspect}", &block)
  end

  def fixture(path)
    IO.read(File.join(FIXTURE_ROOT, path))
  end
end
