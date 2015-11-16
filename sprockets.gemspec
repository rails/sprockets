$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'sprockets/version'

Gem::Specification.new do |s|
  s.name = 'sprockets'
  s.version = Sprockets::VERSION
  s.summary = 'Rack-based asset packaging system'
  s.description = 'Sprockets is a Rack-based asset packaging system that concatenates and serves JavaScript, CoffeeScript, CSS, LESS, Sass, and SCSS.'
  s.license = 'MIT'

  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', 'lib/**/*.rb']
  s.executables = ['sprockets']

  s.add_dependency 'rack', '>= 1', '< 3'

  s.add_development_dependency 'babel-transpiler', '~> 0.6'
  s.add_development_dependency 'closure-compiler', '~> 1.1'
  s.add_development_dependency 'coffee-script-source', '~> 1.6'
  s.add_development_dependency 'coffee-script', '~> 2.2'
  s.add_development_dependency 'eco', '~> 1.0'
  s.add_development_dependency 'ejs', '~> 1.0'
  s.add_development_dependency 'execjs', '~> 2.0'
  s.add_development_dependency 'jsminc', '~> 1.1'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'nokogiri', '~> 1.3'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'sass', '~> 3.4'
  s.add_development_dependency 'sassc', '~> 1.7'
  s.add_development_dependency 'uglifier', '~> 2.3'
  s.add_development_dependency 'yui-compressor', '~> 0.12'

  s.required_ruby_version = '>= 2.0.0'

  s.authors = ['Sam Stephenson', 'Joshua Peek']
  s.email = ['sstephenson@gmail.com', 'josh@joshpeek.com']
  s.homepage = 'https://github.com/rails/sprockets'
  s.rubyforge_project = 'sprockets'
end
