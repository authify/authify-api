#\ -s puma

require 'authify/api'

use Rack::ShowExceptions

run Rack::URLMap.new \
  '/'     => Authify::API::Services::API.new,
  '/jwt'  => Authify::API::Services::JWTProvider.new
