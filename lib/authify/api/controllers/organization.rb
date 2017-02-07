module Authify
  module API
    module Controllers
      Organization = proc do
        helpers do
          def find(id)
            Models::Organization.find(id.to_i)
          end
        end

        index do
          Models::Organization.all
        end

        show do
          last_modified resource.updated_at
          next resource
        end

        show_many do |ids|
          Models::Organization.find(ids)
        end

        destroy(roles: [:admin]) do
          resource.destroy if @current_user.admin_for?(resource)
        end

        has_many :users do
          fetch do
            resource.users
          end
        end

        has_many :admins do
          fetch do
            resource.admins
          end
        end

        has_many :groups do
          fetch do
            resource.groups
          end
        end
      end
    end
  end
end
