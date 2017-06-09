require 'spec_helper'

# Tests for the /registration endpoints
describe Authify::API::Services::Registration do
  include Rack::Test::Methods

  def app
    Authify::API::Services::Registration
  end

  context 'mounted at /registration' do
    # /signup
    context 'signup endpoint' do
      let(:password_signup_data) do
        {
          'email'    => 'second.user@example.com',
          'password' => 'seconduser1234'
        }
      end

      let(:identity_signup_data) do
        {
          'email'    => 'third.user@example.com',
          'via' => {
            'provider' => 'facetube',
            'uid'      => '23456'
          }
        }
      end

      let(:signup_with_template_data) do
        {
          'email'     => 'template.user@example.com',
          'password'  => 'templateuser1234',
          'templates' => {
            'email' => {
              'body' => 'Your code is: {{token}}'
            }
          }
        }
      end

      let(:signup_with_encoded_template_data) do
        {
          'email'     => 'encoded.user@example.com',
          'password'  => 'encodeduser1234',
          'templates' => {
            'email' => {
              'body' => '{base64}VGhpcyB3YXMgZW5jb2RlZDoge3t0b2tlbn19'
            }
          }
        }
      end

      context 'OPTIONS /signup' do
        it 'returns 200 with expected headers' do
          options '/signup'

          # Should respond with a 200
          expect(last_response.status).to eq(200)
          expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
        end
      end

      context 'POST /signup' do
        it 'allows registration via email and password' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/signup', password_signup_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(3)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(false)
          expect(details['email']).to eq(password_signup_data['email'])
          expect(details['id']).to eq(4)
        end

        it 'allows registration via email and password and an email body template' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/signup', signup_with_template_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(3)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(false)
          expect(details['email']).to eq(signup_with_template_data['email'])
          expect(details['id']).to eq(5)
          expect(
            Resque.sample_queues['mailer'][:samples].last['args'].last['body']
          ).to match(/^Your code is: [a-z0-9]+$/)
        end

        it 'allows registration via email and password and an encoded template' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/signup', signup_with_encoded_template_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(3)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(false)
          expect(details['email']).to eq(signup_with_encoded_template_data['email'])
          expect(details['id']).to eq(6)
          expect(
            Resque.sample_queues['mailer'][:samples].last['args'].last['body']
          ).to match(/^This was encoded: [a-z0-9]+$/)
        end

        it 'allows registration via delegate and identity' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          header 'X-Authify-Access', RSpec.configuration.trusted_delegate.access_key
          header 'X-Authify-Secret', RSpec.configuration.trusted_delegate.secret_key
          post '/signup', identity_signup_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(4)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(true)
          expect(details).to have_key('jwt')
          expect(details['email']).to eq(identity_signup_data['email'])
          expect(details['id']).to eq(7)
        end
      end
    end

    context 'forgot_password endpoint' do
      let(:forgot_password_data) do
        {
          'email' => 'third.user@example.com'
        }
      end

      let(:password_reset_data) do
        u = Authify::API::Models::User.find_by_email('third.user@example.com')
        full_token = u.verification_token
        {
          'email'    => 'third.user@example.com',
          'password' => 'thirduser1234',
          'token'    => full_token.split(':').first
        }
      end

      let(:invalid_data) do
        {
          'email' => 'nonexistent@example.com'
        }
      end

      context 'POST /forgot_password' do
        it 'sets a verification token' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          expect(
            Authify::API::Models::User.find_by_email(
              forgot_password_data['email']
            ).verification_token
          ).to eq(nil)
          post '/forgot_password', forgot_password_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('{}')
          expect(
            Authify::API::Models::User.find_by_email(
              forgot_password_data['email']
            ).verification_token
          ).not_to eq(nil)
        end

        it 'allows resetting a password' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/forgot_password', password_reset_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)
          expect(details.size).to eq(4)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(true)
          expect(details).to have_key('jwt')
          expect(details['email']).to eq(password_reset_data['email'])
          expect(
            Authify::API::Models::User.find_by_email('third.user@example.com').authenticate(
              password_reset_data['password']
            )
          ).to eq(true)
        end

        it 'can not be used to find users' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'
          post '/forgot_password', invalid_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq('{}')
        end
      end
    end

    context 'verify endpoint' do
      let(:verification_data) do
        u = Authify::API::Models::User.find_by_email('template.user@example.com')
        full_token = u.verification_token
        {
          'email'    => 'template.user@example.com',
          'password' => 'templateuser1234',
          'token'    => full_token.split(':').first
        }
      end

      context 'OPTIONS /verify' do
        it 'returns 200 with expected headers' do
          options '/verify'

          # Should respond with a 200
          expect(last_response.status).to eq(200)
          expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
        end
      end

      context 'POST /verify' do
        it 'allows verifying a token' do
          header 'Accept', 'application/json'
          header 'Content-Type', 'application/json'

          expect(
            Authify::API::Models::User.find_by_email('template.user@example.com').verified?
          ).not_to eq(true)

          post '/verify', verification_data.to_json

          # Should respond with a 200
          expect(last_response.status).to eq(200)

          details = JSON.parse(last_response.body)

          expect(details.size).to eq(4)
          expect(details).to have_key('verified')
          expect(details['verified']).to be(true)
          expect(details).to have_key('jwt')
          expect(details['email']).to eq(verification_data['email'])
          expect(
            Authify::API::Models::User.find_by_email('template.user@example.com').verified?
          ).to eq(true)
        end
      end
    end
  end
end
