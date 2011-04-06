Gem::Specification.new do |s|
  s.name = "sprockets"
  s.version = "2.0.0"
  s.summary = "Rack-based asset packaging system"
  s.description = "Sprockets is a Rack-based asset packaging system that concatenates and serves JavaScript, CoffeeScript, CSS, LESS, Sass, and SCSS."

  s.files = Dir["Rakefile", "lib/**/*"]

  s.add_dependency "hike", ">= 0.5.0"
  s.add_dependency "rack", ">= 1.0.0"
  s.add_dependency "tilt", ">= 1.1.0"
  s.add_development_dependency "closure-compiler", ">= 1.0.0"
  s.add_development_dependency "yui-compressor", ">= 0.9.4"

  s.authors = ["Sam Stephenson", "Joshua Peek"]
  s.email = "sstephenson@gmail.com"
  s.homepage = "http://getsprockets.org/"
  s.rubyforge_project = "sprockets"
end
