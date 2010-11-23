Gem::Specification.new do |s|
  s.name = "sprockets"
  s.version = "2.0.0"
  s.date = "2010-11-22"
  s.summary = "JavaScript dependency management and concatenation"
  s.description = "Sprockets is a Ruby library that preprocesses and concatenates JavaScript source files."

  s.files = Dir["Rakefile", "lib/**/*"]

  s.add_dependency "hike"

  s.authors = ["Sam Stephenson", "Joshua Peek"]
  s.email = "sstephenson@gmail.com"
  s.homepage = "http://getsprockets.org/"
  s.rubyforge_project = "sprockets"
end
