module Authify
  module API
    module Controllers
      Organization = proc do
        helpers do
          def find(id)
            Models::Organization.includes(:users, :groups, :admins).find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :owner if resource && current_user.admin_for?(resource)
              a << :member if resource && resource.users.include?(current_user)
            end.uniq
          end

          def modifiable_fields
            %i[
              name
              public_email
              gravatar_email
              billing_email
              description
              url
              location
            ]
          end

          def filtered_attributes(attributes)
            attributes.select do |k, _v|
              modifiable_fields.include?(k)
            end
          end

          def filter(collection, fields = {})
            collection.where(fields)
          end

          def sort(collection, fields = {})
            collection.order(fields)
          end
        end

        index(roles: %i[admin user]) do
          Models::Organization.includes(:users, :groups, :admins)
        end

        get '/mine' do
          halt(403) unless can?(:create)
          serialize_models current_user.organizations.includes(:users, :groups, :admins)
        end

        show(roles: [:user]) do
          last_modified resource.updated_at
          exclude = []
          unless role?(:admin, :owner)
            exclude << 'billing_email'
            exclude << 'gravatar_email'
          end
          next resource, exclude: exclude
        end

        show_many do |ids|
          Models::Organization.includes(:users, :groups, :admins).find(ids)
        end

        create(roles: [:user]) do |attrs|
          o = Models::Organization.new filtered_attributes(attrs)
          new_member = Models::OrganizationMembership.new(user: current_user, admin: true)
          o.organization_memberships << new_member
          o.save
          next o.id, o
        end

        update(roles: %i[owner admin]) do |attrs|
          resource.update filtered_attributes(attrs)
          next resource
        end

        destroy(roles: %i[owner admin]) do
          resource.destroy
        end

        has_many :users do
          fetch(roles: %i[owner admin member]) do
            resource.users
          end
        end

        has_many :admins do
          fetch(roles: %i[owner admin member]) do
            resource.admins
          end
        end

        has_many :groups do
          fetch(roles: %i[owner admin member]) do
            resource.groups
          end
        end
      end
    end
  end
end
