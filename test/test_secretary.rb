require "test_helper"

class SecretaryTest < Test::Unit::TestCase
  def test_load_locations_are_not_expanded_when_expand_paths_is_false
    secretary = Sprockets::Secretary.new(:root => FIXTURES_PATH)
    secretary.add_load_locations("src/**/", :expand_paths => false)
    
    assert_equal [File.join(FIXTURES_PATH, "src/**"), FIXTURES_PATH], 
                 secretary.environment.load_path.map { |pathname| pathname.absolute_location }
  end
  
  def test_load_locations_are_expanded_when_expand_paths_is_true
    secretary = Sprockets::Secretary.new(:root => FIXTURES_PATH)
    secretary.add_load_locations("src/**/", :expand_paths => true)
    
    assert_equal [File.join(FIXTURES_PATH, "src", "foo"), File.join(FIXTURES_PATH, "src"), FIXTURES_PATH],
                 secretary.environment.load_path.map { |pathname| pathname.absolute_location }
  end
  
  def test_source_files_are_not_expanded_when_expand_paths_is_false
    secretary = Sprockets::Secretary.new(:root => FIXTURES_PATH)
    assert_raises(Sprockets::LoadError) do
      secretary.add_source_files("src/f*.js", :expand_paths => false)
    end
  end
  
  def test_source_files_are_expanded_when_expand_paths_is_true
    secretary = Sprockets::Secretary.new(:root => FIXTURES_PATH)
    secretary.add_source_files("src/f*.js", :expand_paths => true)
    
    assert_equal [File.join(FIXTURES_PATH, "src", "foo.js")],
                 secretary.preprocessor.source_files.map { |source_file| source_file.pathname.absolute_location }
  end
end
