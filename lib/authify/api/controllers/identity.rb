module Authify
  module API
    module Controllers
      Identity = proc do
        helpers do
          def find(id)
            Models::Identity.find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :myself if current_user && current_user.identities.include?(resource)
            end.uniq
          end
        end

        index(roles: %i(admin trusted)) do
          Models::Identity.all
        end

        show(roles: %i(myself admin trusted)) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:user]) do |attributes|
          ident = Models::Identity.new attributes
          current_user.identities << ident
          current_user.save
          next ident.id, ident
        end

        destroy(roles: %i(myself admin)) do
          resource.destroy
        end

        show_many do |ids|
          Models::Identity.find(ids)
        end

        has_one :user do
          pluck(roles: %i(myself admin trusted)) do
            resource.user
          end
        end
      end
    end
  end
end
