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

include Authify::API::Helpers::JWTEncryption

RSpec.configure do |config|
  # Global rspec resources... use sparingly
  config.add_setting :test_user
  config.add_setting :test_user_apikey
  config.add_setting :test_user_identity
  config.add_setting :test_user_token
  config.add_setting :bad_user
  config.add_setting :bad_user_token
  config.add_setting :admin_user
  config.add_setting :admin_user_token
  config.add_setting :trusted_delegate
  config.add_setting :organization
  config.add_setting :group

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
    user.verified = true
    user.save
    RSpec.configuration.test_user = user
    RSpec.configuration.test_user_apikey = key
    RSpec.configuration.test_user_identity = identity

    # A pre-built user for misbehaving
    bad_user = Authify::API::Models::User.new(
      email: 'bad.user@example.com',
      full_name: 'Bad User'
    )
    bad_user.password = 'baduser123'
    bad_user.save
    RSpec.configuration.bad_user = bad_user

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

    # An organization for testing
    org = Authify::API::Models::Organization.new(
      name: 'Test Organization',
      description: 'A test organization'
    )
    new_member = Authify::API::Models::OrganizationMembership.new(user: user, admin: true)
    org.organization_memberships << new_member
    org.save
    # A group for testing
    group = Authify::API::Models::Group.new(
      name: 'users',
      description: 'A test users group'
    )
    org.groups << group
    org.save
    group.users << user
    group.save
    RSpec.configuration.organization = org
    RSpec.configuration.group = group

    # A user JWT for authentication
    RSpec.configuration.test_user_token = jwt_token(user)

    # A user JWT for authentication
    RSpec.configuration.bad_user_token = jwt_token(bad_user)

    # An admin JWT for authentication
    RSpec.configuration.admin_user_token = jwt_token(admin_user)
  end

  config.after(:suite) do
    FileUtils.rm_rf File.dirname(ENV['AUTHIFY_PUBKEY_PATH'])
    FileUtils.mv File.join('db', 'schema.rb.orig'), File.join('db', 'schema.rb')
  end
end
