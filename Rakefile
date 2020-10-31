require "bundler/gem_tasks"
require "rake/testtask"
require "bundler"

Bundler.setup

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList["test/test.rb"]
  t.warning = false
end

task :default => :test
