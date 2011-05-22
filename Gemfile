source :rubygems
gemspec

if ENV['CI']
  if RUBY_ENGINE == 'jruby'
    gem 'therubyrhino'
  else
    gem 'therubyracer'
  end
end
