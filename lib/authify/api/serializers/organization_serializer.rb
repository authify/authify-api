module Authify
  module API
    module Serializers
      # JSON API Serializer for Organization model
      class OrganizationSerializer
        include JSONAPI::Serializer

        attribute :name
        attribute :description
        attribute :created_at

        has_many :groups
        has_many :users
        has_many :admins
      end
    end
  end
end
