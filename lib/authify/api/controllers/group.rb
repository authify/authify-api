module Authify
  module API
    module Controllers
      Group = proc do
        helpers do
          def find(id)
            Models::Group.find(id.to_i)
          end
        end

        index do
          Models::Group.all
        end

        show do
          last_modified resource.updated_at
          next resource
        end

        show_many do |ids|
          Models::Group.find(ids)
        end

        destroy do
          resource.destroy
        end

        has_many :users do
          fetch do
            resource.users
          end
        end
      end
    end
  end
end
