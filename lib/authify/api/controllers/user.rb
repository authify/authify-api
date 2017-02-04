module Authify
  module API
    module Controllers
      User = proc do
        helpers do
          def find(id)
            Models::User.find(id.to_i)
          end
        end

        index do
          Models::User.all
        end

        show do
          last_modified resource.updated_at
          next resource
        end

        show_many do |ids|
          Models::User.find(ids)
        end

        has_many :api_keys do
          fetch do
            resource.api_keys
          end

          clear do
            resource.api_keys.destroy_all
            resource.save
          end

          subtract do |rios|
            refs = rios.map { |attrs| Models::APIKey.new(attrs) }
            resource.api_keys.destroy(refs)
            resource.save
          end
        end

        has_many :identities do
          fetch do
            resource.identities
          end

          clear do
            resource.identities.destroy_all
            resource.save
          end

          subtract do |rios|
            refs = rios.map { |attrs| Models::Identities.new(attrs) }
            resource.identities.destroy(refs)
            resource.save
          end
        end

        has_many :organizations do
          fetch do
            resource.organizations
          end
        end

        has_many :groups do
          fetch do
            resource.groups
          end
        end
      end
    end
  end
end
