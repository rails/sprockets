source :rubygems
gemspec

if ENV['CI']
  platforms :ruby do
    gem 'therubyracer'
  end

  platforms :jruby do
    gem 'therubyrhino'
  end
end
