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

begin
  require "rubocop/rake_task"

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.options = ['--display-cop-names']
  end
rescue LoadError
  # We are in the production environment, where Rubocop is not required.
end
