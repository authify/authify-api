# Standard Library Requirements

# External Requirements
require 'authify/core'
require 'authify/middleware'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'jsonapi-serializers'
require 'sinatra/jsonapi'
require 'tilt/erb'
require 'connection_pool'
require 'moneta'

# Internal Requirements
module Authify
  module API
    CONFIG = Core::CONFIG.merge(
      db: {
        url: ENV['AUTHIFY_DB_URL'] || 'mysql2://root@localhost:3306/authifydb'
      },
      session_secret: ENV['AUTHIFY_SESSION_SECRET'] || '1q2w3e4r5t6y7u8i9o0pazsxdcfvgbhnjmkl10zm',
      redis: {
        host: ENV['AUTHIFY_REDIS_HOST'] || 'localhost',
        port: ENV['AUTHIFY_REDIS_PORT'] || '6379'
      }
    )
  end
end

require 'authify/api/version'
require 'authify/api/jsonapi_utils'
require 'authify/api/controllers/api_key'
require 'authify/api/controllers/group'
require 'authify/api/controllers/organization'
require 'authify/api/controllers/user'
require 'authify/api/serializers/api_key_serializer'
require 'authify/api/serializers/group_serializer'
require 'authify/api/serializers/user_serializer'
require 'authify/api/serializers/organization_serializer'
require 'authify/api/models/api_key'
require 'authify/api/models/group'
require 'authify/api/models/identity'
require 'authify/api/models/organization'
require 'authify/api/models/organization_membership'
require 'authify/api/models/trusted_delegate'
require 'authify/api/models/user'
require 'authify/api/helpers/jwt_encryption'
require 'authify/api/helpers/api_user'
require 'authify/api/service'
require 'authify/api/services/api'
require 'authify/api/services/jwt_provider'
