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

namespace :delegate do
  desc 'Add a Trusted Delegate'
  task :add, [:name] do |t, args|
    require 'authify/api'
    td = Authify::API::Models::TrustedDelegate.new(
      name: args[:name],
      access_key: Authify::API::Models::TrustedDelegate.generate_access_key
    )
    td.set_secret!
    if td.save
      p({ access: td.access_key, secret: td.secret_key })
    else
      puts "Failed to save Trusted Delegate"
      exit 1
    end
  end
end
