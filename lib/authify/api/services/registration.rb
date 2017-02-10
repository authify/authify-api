module Authify
  module API
    module Services
      # A Sinatra App specifically for registering with the system
      class Registration < Service
        configure do
          set :protection, except: :http_origin
        end

        before '*' do
          content_type 'application/json'
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => %w(
                    OPTIONS
                    GET
                    POST
                  )

          begin
            unless request.get? || request.options?
              request.body.rewind
              @parsed_body = JSON.parse(request.body.read, symbolize_names: true)
            end
          rescue => e
            halt(400, { error: "Request must be valid JSON: #{e.message}" }.to_json)
          end
        end

        post '/signup' do
          email = @parsed_body[:email]
          via = @parsed_body[:via]
          password = @parsed_body[:password]
          name = @parsed_body[:name]
          halt(422, 'Duplicate User') if Models::User.exists?(email: email)

          new_user = Models::User.new(email: email)
          new_user.full_name = name if name
          new_user.password = password
          if via && via[:provider]
            new_user.identities.build(
              provider: via[:provider],
              uid: via[:uid] ? via[:uid] : email
            )
          end
          new_user.save
          { id: new_user.id, email: new_user.email, jwt: jwt_token(new_user) }.to_json
        end
      end
    end
  end
end
