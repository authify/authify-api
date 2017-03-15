require 'spec_helper'

describe Authify::API::Services::JWTProvider do
  include Rack::Test::Methods

  def app
    Authify::API::Services::JWTProvider
  end

  # /meta and /key
  context 'informational endpoints' do
    let(:expected_meta) do
      {
        'algorithm'  => ENV['AUTHIFY_JWT_ALGORITHM'],
        'issuer'     => 'My Awesome Company Inc.',
        'expiration' => 15
      }
    end

    let(:jwt_public_key) do
      File.read(ENV['AUTHIFY_PUBKEY_PATH'])
    end

    it 'provides JWT meta information' do
      header 'Accept', 'application/json'
      get '/meta'

      # Should respond with a 200
      expect(last_response.status).to eq(200)

      details = JSON.parse(last_response.body)

      expect(details.size).to eq(3)
      expect(details).to eq(expected_meta)
    end

    it 'provides the JWT public key' do
      header 'Accept', 'application/json'
      get '/key'

      # Should respond with a 200
      expect(last_response.status).to eq(200)

      details = JSON.parse(last_response.body)

      expect(details.size).to eq(1)
      expect(details).to eq('data' => jwt_public_key)
    end
  end

  # /token
  context 'token provider endpoint' do
    context 'with incorrect credentials' do
      it 'returns 401' do
        header 'Accept', 'application/json'
        post '/token', {
          'email' => RSpec.configuration.test_user.email,
          'password' => 'foobar123'
        }.to_json

        # Should respond with a 401
        expect(last_response.status).to eq(401)
      end
    end

    context 'using an email and password' do
      it 'provides a usable JWT' do
        header 'Accept', 'application/json'
        post '/token', {
          'email' => RSpec.configuration.test_user.email,
          'password' => 'testuser123'
        }.to_json

        # Should respond with a 200
        expect(last_response.status).to eq(200)

        details = JSON.parse(last_response.body)

        expect(details.size).to eq(1)
        expect(details).to have_key('jwt')
      end
    end
  end
end
