module Authify
  module API
    module Serializers
      # JSON API Serializer for Group model
      class GroupSerializer
        include JSONAPI::Serializer

        attribute :name
        attribute :description
        attribute :created_at

        has_one :organization
        has_many :users
      end
    end
  end
end
