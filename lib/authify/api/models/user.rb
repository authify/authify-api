module Authify
  module API
    module Models
      # A User of the system
      class User < ActiveRecord::Base
        include Core::SecureHashing
        include JSONAPIUtils
        include Helpers::TextProcessing

        attr_reader :password

        validates_uniqueness_of :email
        validates_format_of :email, with: /[-a-z0-9_+\.+]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}/i

        has_many :apikeys,
                 class_name: 'Authify::API::Models::APIKey',
                 dependent: :destroy

        has_many :identities,
                 class_name: 'Authify::API::Models::Identity',
                 dependent: :destroy

        has_many :organization_memberships,
                 class_name: 'Authify::API::Models::OrganizationMembership',
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
          return false unless password_digest && !password_digest.empty?
          compare_salted_sha512(unencrypted_password, password_digest)
        end

        def verify(vtoken)
          return false unless verification_token
          token, valid_until = verification_token.split(':')
          token == vtoken && Time.now.to_i <= Integer(valid_until)
        end

        # Both sets a token in the DB *and* emails it to the user
        def add_verification_token!(opts = {})
          return false if verified?
          token = peppered_sha512(rand(999).to_s)[0...16]
          valid_time  = Time.now + (15 * 60)
          valid_until = valid_time.to_i
          self.verification_token = "#{token}:#{valid_until}"

          subdata = { 'token' => token, 'valid_until' => valid_time }

          email_opts = {
            body: if opts.key?(:body)
                    dehandlebar(opts[:body], subdata)
                  else
                    "Your verification token is: #{token}"
                  end
          }

          email_opts[:html_body] = dehandlebar(opts[:html_body], subdata) if opts.key?(:html_body)
          subject = if opts.key?(:subject)
                      dehandlebar(opts[:subject], subdata)
                    else
                      'Authify Verification Email'
                    end

          Resque.enqueue Authify::Core::Jobs::Email, email, subject, email_opts
        end

        def admin_for?(organization)
          admin? || organization.admins.include?(self)
        end

        def self.from_api_key(access, secret)
          key = APIKey.find_by_access_key(access)
          verification_truthiness = (key.user.verified? || !CONFIG[:verifications][:required])
          key.user if key && key.compare_secret(secret) && verification_truthiness
        end

        def self.from_email(email, password)
          found_user = Models::User.find_by_email(email)
          verification_truthiness = (found_user.verified? || !CONFIG[:verifications][:required])
          found_user if found_user && found_user.authenticate(password) && verification_truthiness
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
