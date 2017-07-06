module Authify
  module API
    module Serializers
      # JSON API Serializer for TrustedDelegate model
      class TrustedDelegateSerializer
        include JSONAPI::Serializer

        def type
          'trusted-delegates'
        end

        attribute :name
        attribute :access_key
        attribute :secret_key
        attribute :created_at
      end
    end
  end
end
