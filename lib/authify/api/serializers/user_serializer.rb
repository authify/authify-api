module Authify
  module API
    module Serializers
      # JSON API Serializer for User model
      class UserSerializer
        include JSONAPI::Serializer

        attribute :email
        attribute :full_name
        attribute :admin
        attribute :created_at

        has_many :apikeys
        has_many :groups
        has_many :organizations
        has_many :identities
      end
    end
  end
end
