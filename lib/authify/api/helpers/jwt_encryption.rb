module Authify
  module API
    module Helpers
      # Helper methods for working with JWT encryption
      module JWTEncryption
        include Core::Helpers::JWTSSL

        def jwt_token
          JWT.encode jwt_payload(current_user), private_key, 'ES256'
        end

        def jwt_payload(user)
          {
            exp: Time.now.to_i + 60 * 60,
            iat: Time.now.to_i,
            iss: CONFIG[:jwt][:issuer],
            scopes: Core::Constants::JWTSCOPES,
            user: {
              username: user.email,
              uid: user.id,
              organizations: user.organizations.map do |o|
                               { name: o.name, oid: o.id, admin: o.admins.include?(user) }
                             end,
              groups: user.groups.map { |g| { name: g.name, gid: g.id } }
            }
          }
        end

        def with_jwt(req, scope)
          scopes, user = req.env.values_at :scopes, :user
          set_current_user Models::User.from_username(user['username'])

          if scopes.include?(scope) && current_user
            yield req
          else
            halt 403
          end
        end
      end
    end
  end
end
