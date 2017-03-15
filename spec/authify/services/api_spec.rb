require 'spec_helper'

describe Authify::API::Services::API do
  include Rack::Test::Methods

  def app
    Authify::API::Services::API
  end

  # /apikeys
  context 'apikey endpoints' do
    it 'require authentication' do
      header 'Accept', 'application/vnd.api+json'
      get '/apikeys'

      # Should respond with a 403
      expect(last_response.status).to eq(403)

      error_details = JSON.parse(last_response.body)['errors']
      error = error_details.last

      # Should only be 1 error
      expect(error_details.size).to eq(1)
      expect(error['title']).to eq('Forbidden Error')
      expect(error['detail']).to eq('You are not authorized to perform this action')
    end
  end

  # /groups
  context 'group endpoints' do
    it 'require authentication' do
      header 'Accept', 'application/vnd.api+json'
      get '/groups'

      # Should respond with a 403
      expect(last_response.status).to eq(403)

      error_details = JSON.parse(last_response.body)['errors']
      error = error_details.last

      # Should only be 1 error
      expect(error_details.size).to eq(1)
      expect(error['title']).to eq('Forbidden Error')
      expect(error['detail']).to eq('You are not authorized to perform this action')
    end
  end

  # /identities
  context 'identity endpoints' do
    it 'require authentication' do
      header 'Accept', 'application/vnd.api+json'
      get '/identities'

      # Should respond with a 403
      expect(last_response.status).to eq(403)

      error_details = JSON.parse(last_response.body)['errors']
      error = error_details.last

      # Should only be 1 error
      expect(error_details.size).to eq(1)
      expect(error['title']).to eq('Forbidden Error')
      expect(error['detail']).to eq('You are not authorized to perform this action')
    end
  end

  # /organizations
  context 'organization endpoints' do
    it 'require authentication' do
      header 'Accept', 'application/vnd.api+json'
      get '/organizations'

      # Should respond with a 403
      expect(last_response.status).to eq(403)

      error_details = JSON.parse(last_response.body)['errors']
      error = error_details.last

      # Should only be 1 error
      expect(error_details.size).to eq(1)
      expect(error['title']).to eq('Forbidden Error')
      expect(error['detail']).to eq('You are not authorized to perform this action')
    end
  end

  # /users
  context 'user endpoints' do
    it 'require authentication' do
      header 'Accept', 'application/vnd.api+json'
      get '/users'

      # Should respond with a 403
      expect(last_response.status).to eq(403)

      error_details = JSON.parse(last_response.body)['errors']
      error = error_details.last

      # Should only be 1 error
      expect(error_details.size).to eq(1)
      expect(error['title']).to eq('Forbidden Error')
      expect(error['detail']).to eq('You are not authorized to perform this action')
    end
  end
end
