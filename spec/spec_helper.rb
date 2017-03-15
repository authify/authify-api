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

RSpec.configure do |config|
  # Global rspec resources... use sparingly
  config.add_setting :test_user
  config.add_setting :test_user_apikey
  config.add_setting :test_user_identity
  config.add_setting :admin_user
  config.add_setting :trusted_delegate

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
      email: 'test.user@example.com',
      full_name: 'Test User'
    )
    user.password = 'testuser123'
    user.save
    # Add an API Key to the user
    key = Authify::API::Models::APIKey.new
    key.populate!
    user.apikeys << key
    user.save
    # Associate an identity with the user
    identity = Authify::API::Models::Identity.new(provider: 'facetube', uid: '12345')
    user.identities << identity
    user.save
    RSpec.configuration.test_user = user
    RSpec.configuration.test_user_apikey = key
    RSpec.configuration.test_user_identity = identity

    # A pre-built global admin user for testing
    admin_user = Authify::API::Models::User.new(
      email: 'admin.user@example.com',
      full_name: 'Admin User',
      admin: true
    )
    admin_user.password = 'adminuser123'
    admin_user.save
    RSpec.configuration.admin_user = admin_user

    # A trusted delegate for testing
    td = Authify::API::Models::TrustedDelegate.new(
      name: 'Test Delegate',
      access_key: Authify::API::Models::TrustedDelegate.generate_access_key
    )
    td.set_secret!
    td.save
    RSpec.configuration.trusted_delegate = td
  end

  config.after(:suite) do
    FileUtils.rm_rf File.dirname(ENV['AUTHIFY_PUBKEY_PATH'])
    FileUtils.mv File.join('db', 'schema.rb.orig'), File.join('db', 'schema.rb')
  end
end
