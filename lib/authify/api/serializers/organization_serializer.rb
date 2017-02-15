module Authify
  module API
    module Serializers
      # JSON API Serializer for Organization model
      class OrganizationSerializer
        include JSONAPI::Serializer

        attribute :name
        attribute :public_email
        attribute :gravatar_email
        attribute :billing_email
        attribute :description
        attribute :url
        attribute :location
        attribute :created_at

        has_many :groups
        has_many :users
        has_many :admins
      end
    end
  end
end
