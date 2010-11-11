require "sprockets_test"

class DirectiveParserTest < Sprockets::TestCase
  test "parsing double-slash comments" do
    directive_parser("double_slash").tap do |parser|
      assert_equal "// Header\n//\n//\n(function() {\n})();\n", parser.processed_source
      assert_equal directives, parser.directives
    end
  end

  test "parsing hash comments" do
    directive_parser("hash").tap do |parser|
      assert_equal "# Header\n#\n#\n(->)()\n", parser.processed_source
      assert_equal directives, parser.directives
    end
  end

  test "parsing slash-star comments" do
    directive_parser("slash_star").tap do |parser|
      assert_equal "/* Header\n *\n *\n */\n\n(function() {\n})();\n", parser.processed_source
      assert_equal directives, parser.directives
    end
  end

  test "parsing triple-hash comments" do
    directive_parser("triple_hash").tap do |parser|
      assert_equal "###\nHeader\n\n\n###\n\n(->)()\n", parser.processed_source
      assert_equal directives, parser.directives
    end
  end

  test "header comment without directives is unmodified" do
    directive_parser("comment_without_directives").tap do |parser|
      assert_equal "/*\n * Comment\n */\n\n(function() {\n})();\n", parser.processed_source
      assert_equal [], parser.directives
    end
  end

  test "directives in comment after header are not parsed" do
    directive_parser("directives_after_header").tap do |parser|
      assert_equal "/*\n * Header\n */\n\n// =require \"x\"\n\n(function() {\n})();\n", parser.processed_source
      assert_equal [], parser.directives
    end
  end

  test "no header" do
    directive_parser("no_header").tap do |parser|
      assert_equal directive_fixture("no_header"), parser.processed_source
      assert_equal [], parser.directives
    end
  end

  test "directive word splitting" do
    directive_parser("directive_word_splitting").tap do |parser|
      assert_equal [
        ["one"],
        ["one", "two"],
        ["one", "two", "three"],
        ["one", "two three"],
        ["six", "seven"]
      ], parser.directives
    end
  end

  def directive_parser(fixture_name)
    Sprockets::DirectiveParser.new(directive_fixture(fixture_name))
  end

  def directive_fixture(name)
    fixture("directives/#{name}")
  end

  def directives
    [["require", "a"], ["require", "b"], ["require", "c"]]
  end
end
