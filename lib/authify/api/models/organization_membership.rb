module Authify
  module API
    module Models
      # Linkage between Organizations and users
      class OrganizationMembership < ActiveRecord::Base
        include JSONAPIUtils

        belongs_to :organization,
                 class_name: 'Authify::API::Models::Organization'

        belongs_to :user,
                 class_name: 'Authify::API::Models::User'
      end
    end
  end
end
