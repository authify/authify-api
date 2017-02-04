module Authify
  module API
    module Models
      # A User of the system
      class User < ActiveRecord::Base
        include Core::SecureHashing
        include JSONAPIUtils

        attr_reader :password

        validates_uniqueness_of :email
        validates_format_of :email, with: /[-a-z0-9_+\.+]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}/i

        validates_presence_of :password_digest

        has_many :api_keys,
                 class_name: 'Authify::API::Models::APIKey',
                 dependent: :destroy

        has_many :identities,
                 class_name: 'Authify::API::Models::Identity',
                 dependent: :destroy

        has_many :organization_memberships,
                 class_name: 'Authify::API::Models::OrganizationMemberships',
                 dependent: :destroy

        has_many :organizations,
                 through: :organization_memberships,
                 class_name: 'Authify::API::Models::Organization'

        has_and_belongs_to_many :groups,
                                class_name: 'Authify::API::Models::Group'

        # Encrypts the password into the password_digest attribute.
        def password=(plain_password)
          @password = plain_password
          self.password_digest = salted_sha512(plain_password) if viable(plain_password)
        end

        def authenticate(unencrypted_password)
          return false unless unencrypted_password && !unencrypted_password.empty?
          compare_salted_sha512(unencrypted_password, password_digest)
        end

        def admin_for?(organization)
          organization.admins.include?(self)
        end

        def self.from_api_key(access, secret)
          key = APIKey.find_by_access_key(access)
          key.user if key && key.compare_secret(secret)
        end

        def self.from_email(email, password)
          found_user = Models::User.find_by_email(email)
          found_user if found_user && found_user.authenticate(password)
        end

        def self.from_identity(provider, uid)
          provided_identity = Identity.find_by_provider_and_uid(provider, uid)
          provided_identity.user if provided_identity
        end

        private

        def viable(string)
          string && !string.empty?
        end
      end
    end
  end
end
