module Authify
  module API
    module Controllers
      TrustedDelegate = proc do
        helpers do
          def find(id)
            Models::TrustedDelegate.find(id.to_i)
          end

          def modifiable_fields
            %i[name]
          end

          def filtered_attributes(attributes)
            attributes.select do |k, _v|
              modifiable_fields.include?(k)
            end
          end
        end

        index(roles: %i[admin]) do
          Models::TrustedDelegate.all
        end

        show(roles: %i[admin]) do
          last_modified resource.updated_at
          next resource, exclude: [:secret_key]
        end

        create(roles: %i[admin]) do |attrs|
          key = Models::TrustedDelegate.new filtered_attributes(attrs)
          key.access_key = Models::TrustedDelegate.generate_access_key
          key.set_secret!
          key.save
          next key.id, key
        end

        destroy(roles: %i[admin]) do
          resource.destroy
        end

        show_many do |ids|
          Models::TrustedDelegate.find(ids)
        end
      end
    end
  end
end
