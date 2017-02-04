module Authify
  module API
    module Models
      class Identity < ActiveRecord::Base
        include JSONAPIUtils

        belongs_to :user,
                   required: true,
                   class_name: 'Authify::API::Models::User'
      end
    end
  end
end
