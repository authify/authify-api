module Authify
  module API
    module Serializers
      class UserSerializer
        include JSONAPI::Serializer

        attribute :email
        attribute :full_name
        has_many :api_keys
        has_many :groups
        has_many :organizations
        has_many :identities
      end
    end
  end
end
