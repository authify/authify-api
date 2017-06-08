require 'spec_helper'

# Tests for the /monitoring endpoints
describe Authify::API::Services::Monitoring do
  include Rack::Test::Methods

  def app
    Authify::API::Services::Monitoring
  end

  context 'mounted at /monitoring' do
    context 'OPTIONS /info' do
      it 'returns 200 with expected headers' do
        options '/info'

        # Should respond with a 200
        expect(last_response.status).to eq(200)
        expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      end
    end

    context 'GET /info' do
      it 'provides metrics information' do
        header 'Accept', 'application/json'
        get '/info'

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details).to be_a(Hash)
        expect(details.size).to be > 0
        expect(details).to have_key('jwt.tokens.provided')
      end
    end
  end
end
