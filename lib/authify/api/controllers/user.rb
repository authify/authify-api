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
              a << :myself if current_user && resource && (resource.id == current_user.id)
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

          def filter(collection, fields = {})
            collection.where(fields)
          end

          def sort(collection, fields = {})
            collection.order(fields)
          end
        end

        index(roles: [:user, :trusted]) do
          Models::User.all
        end

        show(roles: [:user, :trusted]) do
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

        has_many :apikeys do
          fetch(roles: [:myself, :admin]) do
            resource.apikeys
          end

          clear(roles: [:myself, :admin]) do
            resource.apikeys.destroy_all
            resource.save
          end

          subtract(roles: [:myself, :admin]) do |rios|
            refs = rios.map { |attrs| Models::APIKey.find(attrs) }
            # This actually calls #destroy on the keys (we don't need orphaned keys)
            resource.apikeys.destroy(refs)
            resource.save
          end
        end

        has_many :identities do
          fetch(roles: [:myself, :admin, :trusted]) do
            resource.identities
          end

          clear(roles: [:myself, :admin]) do
            resource.identities.destroy_all
            resource.save
          end

          merge(roles: [:myself]) do |rios|
            refs = rios.map { |attrs| Models::Identities.new(attrs) }
            resource.identities << refs
            resource.save
          end

          subtract(roles: [:myself, :admin]) do |rios|
            refs = rios.map { |attrs| Models::Identities.find(attrs) }
            resource.identities.destroy(refs)
            resource.save
          end
        end

        has_many :organizations do
          fetch(roles: [:user, :myself]) do
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
