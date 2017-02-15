module Authify
  module API
    module Controllers
      Organization = proc do
        helpers do
          def find(id)
            Models::Organization.find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :owner if resource && current_user.admin_for?(resource)
              a << :member if resource && resource.users.include?(current_user)
            end.uniq
          end

          def modifiable_fields
            [
              :name,
              :public_email,
              :gravatar_email,
              :billing_email,
              :description,
              :url,
              :location
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

        index(roles: [:admin]) do
          Models::Organization.all
        end

        get '/mine' do
          halt(403) unless can?(:create)
          serialize_models current_user.organizations
        end

        show(roles: [:user]) do
          last_modified resource.updated_at
          next resource
        end

        show_many do |ids|
          Models::Organization.find(ids)
        end

        create(roles: [:user]) do |attrs|
          o = Models::Organization.new(attrs)
          o.admins << current_user
          o.save
          next o
        end

        update(roles: [:owner, :admin]) do |attrs|
          resource.update filtered_attributes(attrs)
          next resource
        end

        destroy(roles: [:owner, :admin]) do
          resource.destroy
        end

        has_many :users do
          fetch(roles: [:owner, :admin, :member]) do
            resource.users
          end
        end

        has_many :admins do
          fetch(roles: [:owner, :admin, :member]) do
            resource.admins
          end
        end

        has_many :groups do
          fetch(roles: [:owner, :admin]) do
            resource.groups
          end
        end
      end
    end
  end
end
