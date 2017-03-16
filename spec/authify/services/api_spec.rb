require 'spec_helper'

describe Authify::API::Services::API do
  include Rack::Test::Methods
  include Authify::API::Helpers::JWTEncryption

  def app
    Authify::API::Services::API
  end

  let(:user_jwt) do
    jwt_token(RSpec.configuration.test_user)
  end

  let(:admin_jwt) do
    jwt_token(RSpec.configuration.admin_user)
  end

  # /apikeys
  context 'apikeys endpoints' do
    context 'GET /apikeys' do
      it 'requires authentication' do
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

      it 'prevents non-admins from listing all API keys' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
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

      it 'allows admins to list all API keys' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{admin_jwt}"
        get '/apikeys'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data'].size).to eq(1)
        expect(details['data'].first).to have_key('type')
        expect(details['data'].first).to have_key('id')
        expect(details['data'].first['id']).to eq('1')
        expect(details['data'].first).to have_key('attributes')
        expect(details['data'].first['attributes']).to have_key('access-key')
        expect(details['data'].first['attributes']).to have_key('secret-key')
        expect(details['data'].first['attributes']).to have_key('created-at')
        expect(details['data'].first).to have_key('links')
        expect(details['data'].first['links']).to eq('self' => '/apikeys/1')
        expect(details['data'].first).to have_key('relationships')
        expect(details['data'].first['relationships']).to eq(
          'user' => {
            'links' => {
              'self' => '/apikeys/1/relationships/user',
              'related' => '/apikeys/1/user'
            }
          }
        )
        expect(details).to have_key('jsonapi')
        expect(details['jsonapi']).to eq('version' => '1.0')
      end
    end
  end

  # /groups
  context 'groups endpoints' do
    context 'GET /groups' do
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
  end

  # /identities
  context 'identity endpoints' do
    context 'GET /identities' do
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
  end

  # /organizations
  context 'organization endpoints' do
    context 'GET /organizations' do
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
  end

  # /users
  context 'user endpoints' do
    context 'GET /users' do
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

    context 'GET /users/:id/apikeys' do
      it 'allows users to list their own API keys' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
        get "/users/#{RSpec.configuration.test_user.id}/apikeys"

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data'].size).to eq(1)
        expect(details['data'].first).to have_key('type')
        expect(details['data'].first).to have_key('id')
        expect(details['data'].first['id']).to eq('1')
        expect(details['data'].first).to have_key('attributes')
        expect(details['data'].first['attributes']).to have_key('access-key')
        expect(details['data'].first['attributes']).to have_key('secret-key')
        expect(details['data'].first['attributes']).to have_key('created-at')
        expect(details['data'].first).to have_key('links')
        expect(details['data'].first['links']).to eq('self' => '/apikeys/1')
        expect(details['data'].first).to have_key('relationships')
        expect(details['data'].first['relationships']).to eq(
          'user' => {
            'links' => {
              'self' => '/apikeys/1/relationships/user',
              'related' => '/apikeys/1/user'
            }
          }
        )
        expect(details).to have_key('jsonapi')
        expect(details['jsonapi']).to eq('version' => '1.0')
      end
    end
  end
end
