module Authify
  module API
    module Serializers
      # JSON API Serializer for Identity model
      class IdentitySerializer
        include JSONAPI::Serializer

        attribute :provider
        attribute :uid
        has_one :user
      end
    end
  end
end
