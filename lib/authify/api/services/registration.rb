module Authify
  module API
    module Services
      # A Sinatra App specifically for registering with the system
      class Registration < Service
        helpers Helpers::APIUser

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
          del_data = @parsed_body[:delegate]
          trusted_delegate = if del_data
                               Models::TrustedDelegate.from_access_key(
                                 del_data[:access],
                                 del_data[:secret]
                               )
                             end

          halt(422, 'Duplicate User') if Models::User.exists?(email: email)
          halt(403, 'Password Required') unless password || trusted_delegate

          new_user = Models::User.new(email: email)
          new_user.full_name = name if name
          new_user.password = password if password
          if via && via[:provider]
            new_user.identities.build(
              provider: via[:provider],
              uid: via[:uid] ? via[:uid] : email
            )
          end
          new_user.save
          update_current_user new_user
          { id: new_user.id, email: new_user.email, jwt: jwt_token(new_user) }.to_json
        end
      end
    end
  end
end
