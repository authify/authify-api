module Authify
  module API
    class Service < Sinatra::Base
      helpers Helpers::JWTEncryption
      register Sinatra::ActiveRecordExtension

      set :database, CONFIG[:db]
    end
  end
end
