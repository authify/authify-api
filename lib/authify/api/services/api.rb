module Authify
  module API
    module Services
      class API < Service
        use Middleware::JWTAuth
        register Sinatra::JSONAPI
        
        configure do
          set :protection, except: :http_origin
        end

        before '*' do
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => [
                    'OPTIONS',
                    'DELETE',
                    'GET',
                    'PATCH',
                    'POST',
                    'PUT'
                  ]
        end

        helpers Helpers::APIUser

        resource :api_keys, &Controllers::APIKey
        resource :groups, &Controllers::Group
        resource :organizations, &Controllers::Organization
        resource :users, &Controllers::User

        freeze_jsonapi
      end
    end
  end
end
