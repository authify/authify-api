module Authify
  module API
    module Controllers
      Group = proc do
        helpers do
          def find(id)
            Models::Group.find(id.to_i)
          end
        end

        index(roles: [:admin]) do
          Models::Group.all
        end

        show(roles: [:admin]) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:admin]) do |attrs|
          Models::Group.new(attrs)
        end

        destroy(roles: [:admin]) do
          resource.destroy
        end

        show_many do |ids|
          Models::Group.find(ids)
        end

        has_many :users do
          fetch(roles: [:admin]) do
            resource.users
          end
        end
      end
    end
  end
end
