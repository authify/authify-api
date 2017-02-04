module Authify
  module API
    # Base class for building Sinatra apps (web services)
    class Service < Sinatra::Base
      helpers Helpers::JWTEncryption
      register Sinatra::ActiveRecordExtension

      set :database, CONFIG[:db]
    end
  end
end
