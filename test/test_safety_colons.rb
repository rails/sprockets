# -*- coding: utf-8 -*-
require 'sprockets_test'
require 'sprockets/safety_colons'

class TestSafetyColons < Sprockets::TestCase
  test "append safety colon to file" do
    input = {
      content_type: 'application/javascript',
      data: "(function() {\n})\n"
    }
    assert_equal "(function() {\n})\n;\n",
      Sprockets::SafetyColons.call(input)
  end

  test "skip safety colon if file is blank" do
    input = { content_type: 'application/javascript' }

    input[:data] = ""
    assert_equal "", Sprockets::SafetyColons.call(input)

    input[:data] = "\n"
    assert_equal "\n", Sprockets::SafetyColons.call(input)

    input[:data] = "  "
    assert_equal "  ", Sprockets::SafetyColons.call(input)
  end

  test "skip safety colon if file already ends in a colon" do
    input = { content_type: 'application/javascript' }

    input[:data] = ";"
    assert_equal ";", Sprockets::SafetyColons.call(input)

    input[:data] = "\n;"
    assert_equal "\n;", Sprockets::SafetyColons.call(input)

    input[:data] = "\n\n;"
    assert_equal "\n\n;", Sprockets::SafetyColons.call(input)

    input[:data] = ";\n"
    assert_equal ";\n", Sprockets::SafetyColons.call(input)

    input[:data] = ";\n\n"
    assert_equal ";\n\n", Sprockets::SafetyColons.call(input)

    input[:data] = "var snowman = \"☃\";\n";
    assert_equal "var snowman = \"☃\";\n", Sprockets::SafetyColons.call(input)
  end
end
