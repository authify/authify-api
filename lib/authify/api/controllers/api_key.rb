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
              a << :myself if current_user.api_keys.include?(resource)
            end.uniq
          end
        end

        index(roles: [:admin]) do
          Models::APIKey.all
        end

        show(roles: [:myself, :admin]) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:user]) do |attributes|
          key = Models::APIKey.new attributes
          current_user.api_keys << key
          current_user.save
          next key
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
