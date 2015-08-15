require "rake/testtask"
require "bundler/gem_tasks"

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.warning = true
end

task :test_isolated do
  Dir["test/test*.rb"].each do |fn|
    ruby "-Ilib:test", "-w", fn
    abort unless $?.success?
  end
end
