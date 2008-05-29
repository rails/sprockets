require "test_helper"

class PreprocessorTest < Test::Unit::TestCase
  def setup
    @environment  = environment_for_fixtures
    @preprocessor = Sprockets::Preprocessor.new(@environment)
  end

  def test_double_slash_comments_that_are_not_requires_should_be_removed_by_default
    require_file_for_this_test
    assert_output_file_does_not_contain_line "// This is a double-slash comment that should not appear in the resulting output file."
    assert_output_file_contains_line "/* This is a slash-star comment that should appear in the resulting output file. */"
  end

  def test_double_slash_comments_that_are_not_requires_should_be_ignored_when_strip_comments_is_false
    @preprocessor = Sprockets::Preprocessor.new(@environment, :strip_comments => false)
    require_file_for_this_test
    assert_output_file_contains_line "// This is a double-slash comment that should appear in the resulting output file."
  end
  
  def test_requiring_a_single_file_should_replace_the_require_comment_with_the_file_contents
    require_file_for_this_test
    assert_output_file_contains <<-LINES
      var before_require;
      var Foo = { };
      var after_require;
    LINES
  end
  
  def test_requiring_a_file_that_does_not_exist_should_raise_an_error
    assert_raises(Sprockets::LoadError) do
      require_file_for_this_test
    end
  end
  
  def test_requiring_the_current_file_should_do_nothing
    require_file_for_this_test
    assert_equal "", output_text
  end
  
  def test_requiring_a_file_after_it_has_already_been_required_should_do_nothing
    require_file_for_this_test
    assert_output_file_contains <<-LINES
      var before_first_require;
      var Foo = { };
      var after_first_require_and_before_second_require;
      var after_second_require;
    LINES
  end
  
  protected
    attr_reader :environment, :preprocessor
    
    def output_file
      preprocessor.output_file
    end
    
    def output_text
      preprocessor.output_file.to_s
    end
    
    def source_lines_matching(line)
      output_file.source_lines.select { |source_line| source_line.line.strip == line }
    end
    
    def require_file(location)
      preprocessor.require(environment.find(location).source_file)
    end
    
    def require_file_for_this_test
      require_file(file_for_this_test)
    end
    
    def file_for_this_test
      caller.map { |c| c[/`(.*?)'$/, 1] }.grep(/^test_/).first[5..-1] + ".js"
    end
    
    def assert_output_file_does_not_contain_line(line)
      assert source_lines_matching(line).empty?
    end
    
    def assert_output_file_contains_line(line)
      assert source_lines_matching(line).any?
    end
    
    def assert_output_file_contains(indented_text)
      lines = indented_text.split($/)
      initial_indent  = lines.first[/^\s*/].length
      unindented_text = lines.map { |line| line[initial_indent..-1] }.join($/)
      assert output_text[unindented_text]
    end
end
