source :rubygems
gemspec

if ENV['CI']
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    gem 'therubyrhino'
  else
    gem 'therubyracer'
  end
end
