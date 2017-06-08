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

  # /organizations
  context 'organization endpoints' do
    let(:new_organization_data) do
      {
        'data' => {
          'type' => 'organizations',
          'attributes' => {
            'name' => 'test2',
            'description' => 'Another test organization',
            'url' => 'http://www.example.com/'
          }
        }
      }
    end

    context 'GET /organizations' do
      it 'requires authentication' do
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

      it 'allows a user to list organizations' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"
        get '/organizations'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data'].size).to eq(1)
        expect(details['data'].first).to have_key('id')
        expect(details['data'].first['id']).to eq('1')
        expect(details['data'].first).to have_key('attributes')
        expect(details['data'].first['attributes']).to have_key('name')
        expect(details['data'].first['attributes']['name']).to eq('test')
        expect(details['data'].first['attributes']).to have_key('description')
        expect(details).to have_key('jsonapi')
        expect(details['jsonapi']).to eq('version' => '1.0')
      end
    end

    context 'POST /organizations' do
      it 'requires authentication' do
        header 'Accept', 'application/vnd.api+json'
        header 'Content-Type', 'application/vnd.api+json'

        post '/organizations', new_organization_data.to_json

        # Should respond with a 403
        expect(last_response.status).to eq(403)

        error_details = JSON.parse(last_response.body)['errors']
        error = error_details.last

        # Should only be 1 error
        expect(error_details.size).to eq(1)
        expect(error['title']).to eq('Forbidden Error')
        expect(error['detail']).to eq('You are not authorized to perform this action')
      end

      it 'allows a user to add an organization' do
        header 'Accept', 'application/vnd.api+json'
        header 'Content-Type', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"

        post '/organizations', new_organization_data.to_json

        # Should respond with a 201
        expect(last_response.status).to eq(201)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(3)
        expect(details).to have_key('data')
        expect(details['data']).to have_key('type')
        expect(details['data']['type']).to eq('organizations')
        expect(details['data']).to have_key('id')
        expect(details['data']['id']).to eq('2')
        expect(details['data']).to have_key('attributes')
        expect(details['data']['attributes']).to have_key('name')
        expect(details['data']['attributes']).to have_key('description')
        expect(details['data']['attributes']).to have_key('location')
        expect(details['data']['attributes']).to have_key('created-at')
        expect(details['data']).to have_key('links')
        expect(details['data']['links']).to eq('self' => '/organizations/2')
        expect(details['data']).to have_key('relationships')
        expect(details['data']['relationships']).to include(
          'admins' => {
            'links' => {
              'self' => '/organizations/2/relationships/admins',
              'related' => '/organizations/2/admins'
            }
          }
        )
        expect(details['data']['relationships']).to include(
          'groups' => {
            'links' => {
              'self' => '/organizations/2/relationships/groups',
              'related' => '/organizations/2/groups'
            }
          }
        )
        expect(details['data']['relationships']).to include(
          'users' => {
            'links' => {
              'self' => '/organizations/2/relationships/users',
              'related' => '/organizations/2/users'
            }
          }
        )
        expect(details).to have_key('jsonapi')
        expect(details['jsonapi']).to eq('version' => '1.0')
      end
    end

    context 'DELETE /organizations/:id' do
      it 'requires authentication' do
        header 'Accept', 'application/vnd.api+json'
        delete '/organizations/2'

        # Should respond with a 403
        expect(last_response.status).to eq(403)

        error_details = JSON.parse(last_response.body)['errors']
        error = error_details.last

        # Should only be 1 error
        expect(error_details.size).to eq(1)
        expect(error['title']).to eq('Forbidden Error')
        expect(error['detail']).to eq('You are not authorized to perform this action')
      end

      it 'prevents users from deleting organizations they do not own' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{bad_user_jwt}"

        delete '/organizations/2'

        # Should respond with a 403
        expect(last_response.status).to eq(403)

        error_details = JSON.parse(last_response.body)['errors']
        error = error_details.last

        # Should only be 1 error
        expect(error_details.size).to eq(1)
        expect(error['title']).to eq('Forbidden Error')
        expect(error['detail']).to eq('You are not authorized to perform this action')
      end

      it 'allows users to delete their own organizations' do
        header 'Accept', 'application/vnd.api+json'
        header 'Authorization', "Bearer #{user_jwt}"

        delete '/organizations/2'

        # Should respond with a 204
        expect(last_response.status).to eq(204)
      end
    end
  end
end
