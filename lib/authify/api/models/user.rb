module Authify
  module API
    module Models
      class User < ActiveRecord::Base
        include Core::SecureHashing
        include JSONAPIUtils

        attr_reader   :password

        validates_uniqueness_of :email
        validates_format_of :email, :with => /[-a-z0-9_+\.+]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}/i

        validates_presence_of :password_digest

        has_many :api_keys,
          class_name: "Authify::API::Models::APIKey",
          dependent: :destroy

        has_many :identities,
          class_name: "Authify::API::Models::Identity",
          dependent: :destroy

        has_many :organization_memberships,
          class_name: "Authify::API::Models::OrganizationMemberships",
          dependent: :destroy

        has_many :organizations,
          through: :organization_memberships,
          class_name: "Authify::API::Models::Organization"

        has_and_belongs_to_many :groups,
          class_name: "Authify::API::Models::Group"

        # Encrypts the password into the password_digest attribute.
        def password=(unencrypted_password)
          @password = unencrypted_password
          if unencrypted_password && !unencrypted_password.empty?
            self.password_digest = salted_sha512(unencrypted_password)
          end
        end

        def authenticate(unencrypted_password)
          return false unless unencrypted_password && !unencrypted_password.empty?
          compare_salted_sha512(unencrypted_password, password_digest)
        end

        def self.from_api_key(access, secret)
          key = APIKey.find_by_access_key(access)
          if key && key.compare_secret(secret)
            key.user
          else
            nil
          end
        end

        def self.from_email(email, password)
          found_user = Models::User.find_by_email(email)
          if found_user && found_user.authenticate(password)
            found_user
          else
            nil
          end
        end

        def self.from_identity(provider, uid)
          provided_identity = Identity.find_by_provider_and_uid(provider, uid)
          if provided_identity
            provided_identity.user
          else
            nil
          end
        end
      end
    end
  end
end
