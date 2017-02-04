module Authify
  module API
    module Controllers
      APIKey = proc do
        helpers do
          def find(id)
            Models::APIKey.find(id.to_i)
          end
        end

        index do
          Models::APIKey.all
        end

        show do
          last_modified resource.updated_at
          next resource
        end

        show_many do |ids|
          Models::APIKey.find(ids)
        end

        destroy do
          resource.destroy
        end

        has_one :user do
          pluck do
            resource.user
          end
        end
      end
    end
  end
end
