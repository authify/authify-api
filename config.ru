#\ -s puma

require 'authify/api'

use Rack::ShowExceptions

run Rack::URLMap.new \
  '/'              => Authify::API::Services::API.new,
  '/jwt'           => Authify::API::Services::JWTProvider.new,
  '/registration'  => Authify::API::Services::Registration.new,
  '/monitoring'    => Authify::API::Services::Monitoring.new
