module Authify
  module API
    module Controllers
      User = proc do
        helpers do
          def find(id)
            Models::User.find(id.to_i)
          end

          def role
            Array(super).tap do |a|
              a << :myself if resource == current_user
            end.uniq
          end

          def modifiable_fields
            [:full_name, :email].tap do |a|
              a << :admin if role.include?(:admin)
            end
          end

          def filtered_attributes(attributes)
            attributes.select do |k, _v|
              modifiable_fields.include?(k)
            end
          end
        end

        index(roles: [:user]) do
          Models::User.all
        end

        show(roles: [:user]) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:admin]) do |attributes|
          user = Models::User.new filtered_attributes(attributes)
          user.save
          next user
        end

        show_many do |ids|
          Models::User.find(ids)
        end

        has_many :api_keys do
          fetch(roles: [:myself, :admin]) do
            resource.api_keys
          end

          clear(roles: [:myself, :admin]) do
            resource.api_keys.destroy_all
            resource.save
          end

          subtract(roles: [:myself, :admin]) do |rios|
            refs = rios.map { |attrs| Models::APIKey.new(attrs) }
            resource.api_keys.destroy(refs)
            resource.save
          end
        end

        has_many :identities do
          fetch(roles: [:myself, :admin]) do
            resource.identities
          end

          clear(roles: [:myself, :admin]) do
            resource.identities.destroy_all
            resource.save
          end

          subtract(roles: [:myself, :admin]) do |rios|
            refs = rios.map { |attrs| Models::Identities.new(attrs) }
            resource.identities.destroy(refs)
            resource.save
          end
        end

        has_many :organizations do
          fetch(roles: [:user]) do
            resource.organizations
          end
        end

        has_many :groups do
          fetch(roles: [:myself, :admin]) do
            resource.groups
          end
        end
      end
    end
  end
end
