module Authify
  module API
    module Models
      # External identities mapped to users (GitHub, Facebook, etc.)
      class Identity < ActiveRecord::Base
        include JSONAPIUtils

        belongs_to :user,
                   required: true,
                   class_name: 'Authify::API::Models::User'
      end
    end
  end
end
