module Authify
  module API
    module Services
      # A Sinatra App specifically for registering with the system
      class Registration < Service
        use Authify::API::Middleware::Metrics
        helpers Helpers::APIUser
        helpers Helpers::TextProcessing

        configure do
          set :protection, except: :http_origin
        end

        before do
          content_type 'application/json'

          begin
            unless request.get? || request.options?
              request.body.rewind
              @parsed_body = JSON.parse(request.body.read, symbolize_names: true)
            end
          rescue => e
            halt(400, { error: "Request must be valid JSON: #{e.message}" }.to_json)
          end
        end

        after do
          headers 'Access-Control-Allow-Origin' => '*',
                  'Access-Control-Allow-Methods' => %w[OPTIONS GET POST],
                  'Access-Control-Allow-Headers' => %w[
                    Origin
                    Accept
                    Accept-Encoding
                    Accept-Language
                    Access-Control-Request-Headers
                    Access-Control-Request-Method
                    Authorization
                    Connection
                    Content-Type
                    Host
                    Referer
                    User-Agent
                    X-Requested-With
                    X-Forwarded-For
                    X-XSRF-Token
                  ]
        end

        post '/signup' do
          email = @parsed_body[:email]
          via = @parsed_body[:via]
          password = @parsed_body[:password]
          name = @parsed_body[:name]
          templates = @parsed_body[:templates]

          halt(422, 'Duplicate User') if Models::User.exists?(email: email)
          halt(403, 'Password Required') unless password || remote_app

          new_user = Models::User.new(email: email)
          new_user.full_name = name if name
          new_user.password = password if password
          if via && via[:provider] && remote_app
            new_user.identities.build(
              provider: via[:provider], uid: via[:uid] ? via[:uid] : email
            )
            new_user.verified = true
          elsif templates && templates.key?(:email)
            new_user.add_verification_token!(decoded_hash(templates[:email]))
          else
            new_user.add_verification_token!
          end

          new_user.save
          update_current_user new_user

          response = { id: new_user.id, email: new_user.email }
          if new_user.verified?
            response[:verified] = true
            response[:jwt]      = jwt_token(user: new_user)
          else
            response[:verified] = false
          end
          response.to_json
        end

        options '/signup' do
          halt 200
        end

        post '/forgot_password' do
          email = @parsed_body[:email]
          token = @parsed_body[:token]
          templates = @parsed_body[:templates]

          halt(200, '{}') unless Models::User.exists?(email: email)
          halt(403, 'Missing Parameters') unless email

          found_user = Models::User.find_by_email(email)
          if token && @parsed_body[:password] && found_user.verify(token)
            found_user.verified = true
            found_user.password = @parsed_body[:password]
            found_user.save
            Metrics.instance.increment('registration.password.resets')
            {
              id: found_user.id,
              email: found_user.email,
              verified: found_user.verified?,
              jwt: jwt_token(user: found_user)
            }.to_json
          else
            found_user.verified = false
            if templates && templates.key?(:email)
              found_user.add_verification_token!(decoded_hash(templates[:email]))
            else
              found_user.add_verification_token!
            end
            found_user.save
            halt(200, '{}')
          end
        end

        options '/forgot_password' do
          halt 200
        end

        post '/verify' do
          email = @parsed_body[:email]
          password = @parsed_body[:password]
          token = @parsed_body[:token]

          halt(422, 'Invalid User') unless Models::User.exists?(email: email)
          halt(403, 'Missing Parameters') unless email && password && token

          found_user = Models::User.find_by_email(email)
          if found_user.authenticate(password) && found_user.verify(token)
            found_user.verified = true
          else
            halt(422, 'Verification Failed')
          end
          found_user.save
          update_current_user found_user

          {
            id: found_user.id,
            email: found_user.email,
            verified: found_user.verified?,
            jwt: jwt_token(user: found_user)
          }.to_json
        end

        options '/verify' do
          halt 200
        end
      end
    end
  end
end
