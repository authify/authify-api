module Authify
  module API
    module Models
      # External identities mapped to users (GitHub, Facebook, etc.)
      class Identity < ActiveRecord::Base
        include JSONAPIUtils

        validates_uniqueness_of :uid, scope: :provider

        belongs_to :user,
                   required: true,
                   class_name: 'Authify::API::Models::User'
      end
    end
  end
end
