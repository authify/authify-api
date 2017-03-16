require 'spec_helper'

describe Authify::API::Services::API do
  include Rack::Test::Methods

  def app
    Authify::API::Services::API
  end

  let(:user_jwt) do
    RSpec.configuration.test_user_token
  end

  let(:admin_jwt) do
    RSpec.configuration.admin_user_token
  end

  # /groups
  context 'groups endpoints' do
    context 'GET /groups' do
      it 'requires authentication' do
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
end
