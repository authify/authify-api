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
              a << :myself if current_user.apikeys.include?(resource)
            end.uniq
          end
        end

        index(roles: [:admin]) do
          Models::APIKey.all
        end

        show(roles: [:myself, :admin]) do
          last_modified resource.updated_at
          next resource, exclude: [:secret_key]
        end

        create(roles: [:user]) do |_attributes|
          key = Models::APIKey.new
          key.populate!
          current_user.apikeys << key
          current_user.save
          next [key.id, key]
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
