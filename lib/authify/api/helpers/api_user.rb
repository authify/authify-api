module Authify
  module API
    module Helpers
      # Helper methods for API users
      module APIUser
        def current_user
          email = env.key?(:user) ? env[:user]['username'] : nil
          @current_user ||= email ? Models::User.find_by_email(email) : nil
        end

        def update_current_user(user)
          found_user = if user.is_a? Authify::API::Models::User
                         user
                       elsif user.is_a? Integer
                         Models::User.find(user)
                       elsif user.is_a? String
                         Models::User.find_by_email(user)
                       end

          halt 422 unless found_user
          @current_user = found_user
        end

        # This shouldn't work via API calls
        def auth
          {}
        end
      end
    end
  end
end
