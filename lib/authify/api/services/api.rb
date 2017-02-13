module Authify
  module API
    module Services
      # The main API Sinatra App
      class API < Service
        use Middleware::JWTAuth
        register Sinatra::JSONAPI

        helpers Helpers::APIUser

        helpers do
          def determine_roles
            on_behalf_of = processed_headers['x_authify_on_behalf_of']
            if !env[:authenticated] && remote_app
              env[:authenticated] = true
              update_current_user on_behalf_of if on_behalf_of
            end

            @roles ||= []
            @roles << :trusted if remote_app && !on_behalf_of
            @roles << :user if env[:authenticated]
            @roles << :admin if current_user && current_user.admin?
          end

          def role
            (@roles || []).uniq
          end
        end

        before '*' do
          # headers 'Access-Control-Allow-Origin' => '*',
          #        'Access-Control-Allow-Methods' => %w(
          #          OPTIONS
          #          DELETE
          #          GET
          #          PATCH
          #          POST
          #          PUT
          #        )
          determine_roles
        end

        resource :apikeys, &Controllers::APIKey
        resource :identities, &Controllers::Identity
        resource :groups, &Controllers::Group
        resource :organizations, &Controllers::Organization
        resource :users, &Controllers::User

        freeze_jsonapi
      end
    end
  end
end
