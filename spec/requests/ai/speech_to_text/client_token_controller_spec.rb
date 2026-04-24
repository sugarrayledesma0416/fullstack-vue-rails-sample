require 'rails_helper'
require 'requests/login_helper_methods'

describe AI::SpeechToText::ClientTokenController do
  describe 'GET new' do
    let(:azure_endpoint) do
      "https://#{AI::AzureClient::REGION}.#{AI::AzureClient::HOST}#{AI::AzureClient::SCOPED_TOKEN_URL}"
    end
    let(:raw_token) { 'fake_token' }

    def do_request(provider = nil)
      if provider
        get ai_speech_to_text_new_client_token_path(provider: provider), as: :json
      else
        get ai_speech_to_text_new_client_token_path, as: :json
      end
    end

    context 'with a logged in user' do
      let(:user) { create(:user) }

      before do
        log_in_user(user)
      end

      context 'when provider is explicitly set to azure' do
        before do
          stub_request(:post, azure_endpoint).and_return(
            body: raw_token,
            status: 200
          )
        end

        it 'returns the token in JSON format with azure provider' do
          do_request('azure')

          expect(response).to be_ok
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.parsed_body).to eq(
            'provider' => 'azure',
            'expires_in' => 600,
            'token' => raw_token
          )
        end
      end

      context 'when provider is explicitly set to andromeda' do
        it 'returns JSON with andromeda provider and no token' do
          do_request('andromeda')

          expect(response).to be_ok
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.parsed_body).to eq(
            'provider' => 'andromeda'
          )
        end
      end

      context 'when provider is auto and feature flag is enabled' do
        before do
          stub_request(:post, azure_endpoint).and_return(
            body: raw_token,
            status: 200
          )

          # Create a mock UNLEASH constant for the test
          stub_const("UNLEASH", double("UNLEASH"))
          allow(UNLEASH).to receive(:is_enabled?).with(described_class::FEATURE_FLAG_SPEECH_REC_UPGRADE, anything).and_return(true)
        end

        it 'returns the token in JSON format with azure provider' do
          do_request('auto')

          expect(response).to be_ok
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.parsed_body).to eq(
            'provider' => 'azure',
            'expires_in' => 600,
            'token' => raw_token
          )
        end
      end

      context 'when provider is auto and feature flag is disabled' do
        before do
          # Create a mock UNLEASH constant for the test
          stub_const("UNLEASH", double("UNLEASH"))
          allow(UNLEASH).to receive(:is_enabled?).with(described_class::FEATURE_FLAG_SPEECH_REC_UPGRADE, anything).and_return(false)
        end

        it 'returns JSON with andromeda provider and no token' do
          do_request('auto')

          expect(response).to be_ok
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.parsed_body).to eq(
            'provider' => 'andromeda'
          )
        end
      end

      context 'when no provider is specified and feature flag is enabled' do
        before do
          stub_request(:post, azure_endpoint).and_return(
            body: raw_token,
            status: 200
          )
          # Create a mock UNLEASH constant for the test
          stub_const("UNLEASH", double("UNLEASH"))
          allow(UNLEASH).to receive(:is_enabled?).with(described_class::FEATURE_FLAG_SPEECH_REC_UPGRADE, anything).and_return(true)
        end

        it 'defaults to andromeda provider' do
          do_request

          expect(response).to be_ok
          expect(response.content_type).to eq('application/json; charset=utf-8')
          expect(response.parsed_body).to eq(
            'provider' => 'andromeda'
          )
        end
      end

      context 'when the token is not generated successfully for azure provider' do
        before do
          stub_request(:post, azure_endpoint).and_return(
            body: { error: 'some error' }.to_json,
            status: 401
          )
        end

        it 'returns an error' do
          do_request('azure')

          expect(response).to be_forbidden
        end
      end
    end

    context 'with a user who is not logged in' do
      it 'returns the unauthorized status' do
        do_request

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
