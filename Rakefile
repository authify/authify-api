require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require 'authify/api'
  end
end

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: [:spec, :rubocop]

desc 'Start the demo using `rackup`'
task :start do
  exec 'rackup config.ru'
end
