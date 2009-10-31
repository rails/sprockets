require "test_helper"

class ConcatenationTest < Test::Unit::TestCase
  def setup
    @concatenation = Sprockets::Concatenation.new
    @environment = environment_for_fixtures
  end

  def test_record
    assert_equal [], @concatenation.source_lines
    assert_equal "hello\n", @concatenation.record(source_line("hello\n")).to_s
    assert_equal "world\n", @concatenation.record(source_line("world\n")).to_s
    assert_equal ["hello\n", "world\n"], @concatenation.source_lines.map { |source_line| source_line.to_s }
  end

  def test_to_s
    @concatenation.record(source_line("hello\n"))
    @concatenation.record(source_line("world\n"))
    assert_equal "hello\nworld\n", @concatenation.to_s
  end

  def test_save_to
    filename = File.join(FIXTURES_PATH, "output.js")
    @concatenation.save_to(filename)
    assert_equal @concatenation.to_s, IO.read(filename)
    File.unlink(filename)
  end

  def test_md5
    @concatenation.record(source_line("hello\n"))
    assert_equal "b1946ac92492d2347c6235b4d2611184", @concatenation.md5

    @concatenation.record(source_line("world\n"))
    assert_equal "0f723ae7f9bf07744445e93ac5595156", @concatenation.md5
  end
end
