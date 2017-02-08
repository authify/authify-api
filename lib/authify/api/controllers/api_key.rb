module Authify
  module API
    module Controllers
      APIKey = proc do
        helpers do
          def find(id)
            Models::APIKey.find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :myself if resource == current_user
            end.uniq
          end
        end

        index(roles: [:myself, :admin]) do
          Models::APIKey.all
        end

        show(roles: [:myself, :admin]) do
          last_modified resource.updated_at
          next resource
        end

        destroy(roles: [:myself, :admin]) do
          resource.destroy
        end

        show_many do |ids|
          Models::APIKey.find(ids)
        end

        has_one :user do
          pluck(roles: [:myself, :admin]) do
            resource.user
          end
        end
      end
    end
  end
end
