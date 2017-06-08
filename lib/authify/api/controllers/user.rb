module Authify
  module API
    module Controllers
      User = proc do
        helpers do
          def before_index
            params[:fields] = only_indexable_fields
          end

          def before_show_many
            params[:fields] = only_indexable_fields
          end

          def before_show
            params[:fields] = only_indexable_fields
          end

          def find(id)
            Models::User.find(id.to_i)
          end

          def role
            Array(super.dup).tap do |a|
              a << :myself if current_user && resource && (resource.id == current_user.id)
            end.uniq
          end

          def modifiable_fields
            %i[full_name email].tap do |a|
              a << :admin if role.include?(:admin)
            end
          end

          def indexable_fields
            %i[full-name admin apikeys groups organizations identities].tap do |a|
              if role?(:admin) || role?(:myself)
                a << :verified
                a << :email
                a << :'created-at'
              end
            end
          end

          def only_indexable_fields
            {
              users: if params[:fields] && params[:fields].key?(:users)
                       params[:fields][:users].select { |k, _| indexable_fields.include?(k) }
                     else
                       indexable_fields
                     end
            }
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

        index(roles: %i[user trusted]) do
          Models::User.all
        end

        show(roles: %i[user trusted]) do
          last_modified resource.updated_at
          next resource
        end

        create(roles: [:admin]) do |attributes|
          user = Models::User.new filtered_attributes(attributes)
          user.save
          next user
        end

        update(roles: %i[admin myself]) do |attrs|
          # Necessary because #password= is overridden for Models::User
          new_pass = attrs[:password] if attrs && attrs.key?(:password)
          resource.update filtered_attributes(attrs)
          resource.password = new_pass if new_pass
          resource.save
          next resource
        end

        show_many do |ids|
          serialize_models Models::User.find(ids), fields: { users: indexable_fields }
        end

        has_many :apikeys do
          fetch(roles: %i[myself admin]) do
            resource.apikeys
          end

          clear(roles: %i[myself admin]) do
            resource.apikeys.destroy_all
            resource.save
          end

          subtract(roles: %i[myself admin]) do |rios|
            refs = rios.map { |attrs| Models::APIKey.find(attrs) }
            # This actually calls #destroy on the keys (we don't need orphaned keys)
            resource.apikeys.destroy(refs)
            resource.save
          end
        end

        has_many :identities do
          fetch(roles: %i[myself admin trusted]) do
            resource.identities
          end

          clear(roles: %i[myself admin]) do
            resource.identities.destroy_all
            resource.save
          end

          merge(roles: [:myself]) do |rios|
            refs = rios.map { |attrs| Models::Identity.new(attrs) }
            resource.identities << refs
            resource.save
          end

          subtract(roles: %i[myself admin]) do |rios|
            refs = rios.map { |attrs| Models::Identity.find(attrs) }
            resource.identities.destroy(refs)
            resource.save
          end
        end

        has_many :organizations do
          fetch(roles: %i[user myself admin]) do
            resource.organizations
          end
        end

        has_many :groups do
          fetch(roles: %i[myself admin]) do
            resource.groups
          end
        end
      end
    end
  end
end
