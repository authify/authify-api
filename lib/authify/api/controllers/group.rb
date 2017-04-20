module Authify
  module API
    module Controllers
      Group = proc do
        helpers do
          def find(id)
            Models::Group.find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :owner if current_user && current_user.admin_for?(resource.organization)
              a << :member if resource && resource.users.include?(current_user)
            end.uniq
          end
        end

        index(roles: [:admin]) do
          Models::Group.all
        end

        show(roles: %i[admin owner]) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:admin]) do |attrs|
          g = Models::Group.new(attrs)
          g.save
          next g
        end

        destroy(roles: %i[admin owner]) do
          resource.destroy
        end

        show_many do |ids|
          Models::Group.find(ids)
        end

        has_many :users do
          fetch(roles: %i[admin owner]) do
            resource.users
          end

          replace(roles: %i[admin owner]) do |rios|
            refs = rios.map { |attrs| Models::User.find(attrs) }
            resource.users = refs
            resource.save
          end

          merge(roles: %i[admin owner]) do |rios|
            refs = rios.map { |attrs| Models::User.find(attrs) }
            resource.users << refs
            resource.save
          end

          subtract(roles: %i[admin owner]) do |rios|
            refs = rios.map { |attrs| Models::User.find(attrs) }
            # This only removes the linkage, not the actual users
            resource.users.delete(refs)
            resource.save
          end
        end
      end
    end
  end
end
