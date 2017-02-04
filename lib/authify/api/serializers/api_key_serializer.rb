module Authify
  module API
    module Serializers
      class APIKeySerializer
        include JSONAPI::Serializer

        attribute :access_key
        has_one :user
      end
    end
  end
end
