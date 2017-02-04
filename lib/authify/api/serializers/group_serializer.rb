module Authify
  module API
    module Serializers
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
