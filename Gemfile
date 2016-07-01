source "https://rubygems.org"
gem "rack", github: 'rack/rack'
gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.2.2")
  gem 'rack', '< 2.0'
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.0")
  gem 'json', '< 2.0'
end
