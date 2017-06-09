require 'spec_helper'

describe Authify::API::Services::API do
  include Rack::Test::Methods

  def app
    Authify::API::Services::API
  end

  let(:user_jwt) do
    RSpec.configuration.test_user_token
  end

  let(:bad_user_jwt) do
    RSpec.configuration.bad_user_token
  end

  let(:admin_jwt) do
    RSpec.configuration.admin_user_token
  end

  # /users
  context 'user endpoints' do
    context 'OPTIONS /users' do
      it 'returns 200 with expected headers' do
        options '/users'

        # Should respond with a 200
        expect(last_response.status).to eq(200)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    context 'GET /users' do
      it 'requires authentication' do
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

      it 'allows users to list all users' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
        get '/users'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data'].size).to eq(3)
        # Make sure we aren't exposing emails for all our users
        expect(details['data'].first['attributes'].keys).not_to include('email')
      end
    end

    context 'GET /users/:id' do
      it 'requires authentication' do
        header 'Accept', 'application/vnd.api+json'
        get '/users/1'

        # Should respond with a 403
        expect(last_response.status).to eq(403)

        error_details = JSON.parse(last_response.body)['errors']
        error = error_details.last

        # Should only be 1 error
        expect(error_details.size).to eq(1)
        expect(error['title']).to eq('Forbidden Error')
        expect(error['detail']).to eq('You are not authorized to perform this action')
      end

      it 'allows users view themselves' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
        get '/users/1'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data']['attributes']['full-name']).to eq('Test User')
        expect(details['data']['attributes'].keys).to include('email')
      end

      it 'allows users view other users' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
        get '/users/2'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data']['attributes']['full-name']).to eq('Bad User')
        # Make sure we aren't exposing emails for all our users
        expect(details['data']['attributes'].keys).not_to include('email')
      end
    end

    context 'POST /users/:id' do
      let(:user_update_data) do
        {
          'data' => {
            'type' => 'users',
            'id' => '1',
            'attributes' => {
              'full-name' => 'Testing Test'
            }
          }
        }
      end

      it 'requires authentication' do
        header 'Accept', 'application/vnd.api+json'
        header 'Content-Type', 'application/vnd.api+json'

        patch '/users/1', user_update_data.to_json

        # Should respond with a 403
        expect(last_response.status).to eq(403)

        error_details = JSON.parse(last_response.body)['errors']
        error = error_details.last

        # Should only be 1 error
        expect(error_details.size).to eq(1)
        expect(error['title']).to eq('Forbidden Error')
        expect(error['detail']).to eq('You are not authorized to perform this action')
      end

      it 'allows users to update their details' do
        header 'Accept', 'application/vnd.api+json'
        header 'Content-Type', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"

        patch '/users/1', user_update_data.to_json

        # Should respond with a 201
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data']).to have_key('id')
        expect(details['data']['id']).to eq('1')
        expect(details['data']).to have_key('attributes')
        expect(details['data']['attributes']).to have_key('full-name')
        expect(details['data']['attributes']['full-name']).to eq('Testing Test')
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
        expect(details['data'].first['type']).to eq('apikeys')
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
