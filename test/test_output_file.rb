require "test_helper"

class OutputFileTest < Test::Unit::TestCase
  def setup
    @output_file = Sprockets::OutputFile.new
  end
  
  def test_record
    assert_equal [], @output_file.source_lines
    assert_equal "hello\n", @output_file.record("hello\n")
    assert_equal "world\n", @output_file.record("world\n")
    assert_equal ["hello\n", "world\n"], @output_file.source_lines
  end
  
  def test_to_s
    @output_file.record(source_line("hello\n"))
    @output_file.record(source_line("world\n"))
    assert_equal "hello\nworld\n", @output_file.to_s
  end
end
