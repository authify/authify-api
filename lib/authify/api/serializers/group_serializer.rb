module Authify
  module API
    module Serializers
      # JSON API Serializer for Group model
      class GroupSerializer
        include JSONAPI::Serializer

        attribute :name
        attribute :description
        has_one :organization
        has_many :users
      end
    end
  end
end
