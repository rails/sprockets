# frozen_string_literal: true
require 'minitest/autorun'
require 'sprockets'
require 'terser'

class TestTerserCompressor < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.js_compressor = Terser.new
    @cache = Sprockets::Cache.new

    @tmpdir = Dir.mktmpdir
    @env.append_path(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir
  end

  def test_terser_configured_as_compressor
    assert_equal :js_compressor, @env.js_compressor
  end

  def test_compress_javascript_through_sprockets
    js_content = "function foo() {\n  return true;\n}"
    file_path = File.join(@tmpdir, 'test.js')
    File.write(file_path, js_content)

    asset = @env['test.js']
    compressed = asset.to_s

    assert compressed.length < js_content.length
    assert compressed.include?('function foo(){return!0}')
    refute compressed.include?("\n  ")
  end

  def test_compress_es6_through_sprockets
    js_content = "const arrow = (x) => {\n  return x * 2;\n}\nlet value = 10;"
    file_path = File.join(@tmpdir, 'test_es6.js')
    File.write(file_path, js_content)

    asset = @env['test_es6.js']
    compressed = asset.to_s

    assert compressed.length < js_content.length
    assert compressed.include?('const arrow=a=>2*a')
    refute compressed.include?("\n  ")
  end

  def test_compress_with_comments_through_sprockets
    js_content = <<~JS
      // This is a single line comment
      function calculate(a, b) {
        /* This is a 
           multi-line comment */
        return a + b;
      }
    JS

    file_path = File.join(@tmpdir, 'test_comments.js')
    File.write(file_path, js_content)

    asset = @env['test_comments.js']
    compressed = asset.to_s

    assert compressed.length < js_content.length
    refute compressed.include?('This is a single line comment')
    refute compressed.include?('multi-line comment')
    assert compressed.include?('function calculate')
  end

  def test_preserve_license_comments_through_sprockets
    js_content = <<~JS
      /*! 
       * Important License Information
       * Copyright (c) 2024
       */
      function licensed() {
        return "code";
      }
    JS

    file_path = File.join(@tmpdir, 'test_license.js')
    File.write(file_path, js_content)

    asset = @env['test_license.js']
    compressed = asset.to_s

    assert compressed.length < js_content.length
    assert compressed.include?('function licensed')
  end

  def test_multiple_files_compression
    file1_content = "var globalVar = 100;\nfunction first() { return globalVar; }"
    file2_content = "function second() { return globalVar * 2; }"

    File.write(File.join(@tmpdir, 'file1.js'), file1_content)
    File.write(File.join(@tmpdir, 'file2.js'), file2_content)

    asset1 = @env['file1.js']
    asset2 = @env['file2.js']

    compressed1 = asset1.to_s
    compressed2 = asset2.to_s

    assert compressed1.length < file1_content.length
    assert compressed2.length < file2_content.length

    assert compressed1.include?('globalVar')
    assert compressed2.include?('globalVar')
  end

  def test_compression_with_syntax_error
    js_content = 'function broken() { this is not valid javascript'
    file_path = File.join(@tmpdir, 'test_error.js')
    File.write(file_path, js_content)

    assert_raises(Terser::Error) do
      @env['test_error.js'].to_s
    end
  end
end
