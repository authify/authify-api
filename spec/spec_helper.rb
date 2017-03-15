$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['RACK_ENV']               = 'test'
ENV['AUTHIFY_JWT_ALGORITHM']  = 'ES512'
base_path                     = File.expand_path(File.join('tmp', 'tests'))
ENV['AUTHIFY_PUBKEY_PATH']    = File.join(base_path, 'public.pem')
ENV['AUTHIFY_PRIVKEY_PATH']   = File.join(base_path, 'private.pem')
ENV['AUTHIFY_DB_URL']         = "sqlite3://#{File.join(base_path, 'authify.db')}"

require 'authify/api'
require 'rack/test'
require 'rspec'
require 'rake'
require 'sinatra/activerecord/rake'

RSpec.configure do |config|
  # Global rspec resources... use sparingly
  config.add_setting :test_user

  config.before(:suite) do
    FileUtils.mkdir_p File.dirname(ENV['AUTHIFY_PUBKEY_PATH'])

    algo = case ENV['AUTHIFY_JWT_ALGORITHM']
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
    File.write(ENV['AUTHIFY_PRIVKEY_PATH'], secret_key.to_pem)
    public_key = secret_key
    public_key.private_key = nil
    # write out the public key to a file...
    File.write(ENV['AUTHIFY_PUBKEY_PATH'], public_key.to_pem)

    # Setup the DB
    FileUtils.mv File.join('db', 'schema.rb'), File.join('db', 'schema.rb.orig')
    `bundle exec rake db:migrate`

    # A pre-built user for testing
    user = Authify::API::Models::User.new(
      email: 'test.user@example.com'
    )
    user.password = 'foobar123'
    user.save
    RSpec.configuration.test_user = user
  end

  config.after(:suite) do
    FileUtils.rm_rf File.dirname(ENV['AUTHIFY_PUBKEY_PATH'])
    FileUtils.mv File.join('db', 'schema.rb.orig'), File.join('db', 'schema.rb')
  end
end
