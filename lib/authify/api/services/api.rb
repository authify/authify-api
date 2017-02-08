module Authify
  module API
    module Services
      # The main API Sinatra App
      class API < Service
        use Middleware::JWTAuth
        register Sinatra::JSONAPI

        configure do
          set :protection, except: :http_origin
        end

        helpers Helpers::APIUser

        helpers do
          def determine_roles
            if !env[:authenticated] && remote_app
              env[:authenticated] = true
              on_behalf_of = processed_headers['x_authify_on_behalf_of']
              update_current_user on_behalf_of if on_behalf_of
            end

            @roles ||= []
            @roles << :user if env[:authenticated]
            @roles << :admin if current_user && current_user.admin?
          end

          def role
            (@roles || []).uniq
          end
        end

        before '*' do
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => %w(
                    OPTIONS
                    DELETE
                    GET
                    PATCH
                    POST
                    PUT
                  )
          determine_roles
        end

        resource :api_keys, &Controllers::APIKey
        resource :groups, &Controllers::Group
        resource :organizations, &Controllers::Organization
        resource :users, &Controllers::User

        freeze_jsonapi
      end
    end
  end
end
