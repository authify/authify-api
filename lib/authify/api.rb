# Standard Library Requirements

# External Requirements
require 'authify/core'
require 'authify/core/jobs/email'
require 'authify/middleware'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'jsonapi-serializers'
require 'sinatra/jsonapi'
require 'tilt/erb'
require 'connection_pool'
require 'moneta'
require 'resque'
require 'hitimes'
require 'liquid'

# Internal Requirements
module Authify
  module API
    CONFIG = Core::CONFIG.merge(
      db: {
        url: ENV['AUTHIFY_DB_URL'] || 'mysql2://root@localhost:3306/authifydb'
      },
      redis: {
        host: ENV['AUTHIFY_REDIS_HOST'] || 'localhost',
        port: ENV['AUTHIFY_REDIS_PORT'] || '6379'
      },
      verifications: {
        required: ENV['AUTHIFY_VERIFICATIONS_REQUIRED'] == 'false' ? false : true
      }
    )
  end
end

redis_config = Authify::API::CONFIG[:redis]
Resque.redis = "#{redis_config[:host]}:#{redis_config[:port]}"

require 'authify/api/version'
require 'authify/api/jsonapi_utils'
require 'authify/api/controllers/apikey'
require 'authify/api/controllers/group'
require 'authify/api/controllers/identity'
require 'authify/api/controllers/organization'
require 'authify/api/controllers/trusted_delegate'
require 'authify/api/controllers/user'
require 'authify/api/serializers/apikey_serializer'
require 'authify/api/serializers/group_serializer'
require 'authify/api/serializers/identity_serializer'
require 'authify/api/serializers/user_serializer'
require 'authify/api/serializers/organization_serializer'
require 'authify/api/serializers/trusted_delegate_serializer'
require 'authify/api/helpers/jwt_encryption'
require 'authify/api/helpers/api_user'
require 'authify/api/helpers/text_processing'
require 'authify/api/models/apikey'
require 'authify/api/models/group'
require 'authify/api/models/identity'
require 'authify/api/models/organization'
require 'authify/api/models/organization_membership'
require 'authify/api/models/trusted_delegate'
require 'authify/api/models/user'
require 'authify/api/service'
require 'authify/api/metrics'
require 'authify/api/middleware/metrics'
require 'authify/api/services/api'
require 'authify/api/services/jwt_provider'
require 'authify/api/services/registration'
require 'authify/api/services/monitoring'
