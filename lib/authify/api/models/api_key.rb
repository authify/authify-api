module Authify
  module API
    module Models
      class APIKey < ActiveRecord::Base
        include Core::SecureHashing
        extend Core::SecureHashing
        include JSONAPIUtils

        attr_reader :secret_key

        validates_presence_of :access_key
        validates_presence_of :secret_key_digest

        belongs_to :user,
                   required: true,
                   class_name: 'Authify::API::Models::User'

        def secret_key=(unencrypted_string)
          @secret_key = unencrypted_string
          if unencrypted_string && !unencrypted_string.empty?
            self.secret_key_digest = salted_sha512(unencrypted_string)
          end
        end

        def compare_secret(unencrypted_string)
          compare_salted_sha512(unencrypted_string, secret_key_digest)
        end

        def set_secret!
          self.secret_key = self.class.generate_access_key + self.class.generate_access_key
        end

        def self.generate_access_key
          to_hex(SecureRandom.gen_random(32))[0...32]
        end
      end
    end
  end
end
