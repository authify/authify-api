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

namespace :jwt do
  desc 'Generate a Signer Certificate'
  task :gencert do
    jwtalgo  = ENV['AUTHIFY_JWT_ALGORITHM']
    privpath = ENV['AUTHIFY_PRIVKEY_PATH']
    pubpath  = ENV['AUTHIFY_PUBKEY_PATH']
    raise 'Missing ENV settings' unless jwtalgo && privpath && pubpath

    require 'authify/api'
    algo = case jwtalgo
           when 'ES256'
             'prime256v1'
           when 'ES384'
             'secp384r1'
           when 'ES512'
             'secp521r1'
           end
    secret_key = OpenSSL::PKey::EC.new(algo)
    secret_key.generate_key
    # write out the private key to a file...
    File.write(File.expand_path(privpath), secret_key.to_pem)
    public_key = secret_key
    public_key.private_key = nil
    # write out the public key to a file...
    File.write(File.expand_path(pubpath), public_key.to_pem)
  end
end

namespace :delegate do
  desc 'Add a Trusted Delegate'
  task :add, [:name] do |_t, args|
    require 'authify/api'
    td = Authify::API::Models::TrustedDelegate.new(
      name: args[:name],
      access_key: Authify::API::Models::TrustedDelegate.generate_access_key
    )
    td.set_secret!
    if td.save
      p(access: td.access_key, secret: td.secret_key)
    else
      puts 'Failed to save Trusted Delegate'
      exit 1
    end
  end

  desc 'List Trusted Delegates'
  task :list do
    require 'authify/api'
    Authify::API::Models::TrustedDelegate.all.each do |td|
      p(name: td.name, access: td.access_key)
    end
  end

  desc 'Delete a Trusted Delegate'
  task :remove, [:name] do |_t, args|
    require 'authify/api'
    td = Authify::API::Models::TrustedDelegate.find_by_name(args[:name])
    if td && td.destroy
      puts 'Trusted Delegate destroyed'
    else
      puts 'Failed to destroy Trusted Delegate'
      exit 1
    end
  end
end

namespace :docker do
  desc 'Build a fresh docker image'
  task :build do
    exec 'docker build -t authify/api .'
  end
end
