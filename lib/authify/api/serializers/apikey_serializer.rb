module Authify
  module API
    module Serializers
      # JSON API Serializer for APIKey model
      class APIKeySerializer
        include JSONAPI::Serializer

        attribute :access_key
        attribute :secret_key
        attribute :created_at

        has_one :user
      end
    end
  end
end
