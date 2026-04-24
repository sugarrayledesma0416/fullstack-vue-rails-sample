describe AI::AzureClient do
  let(:client) { described_class.new }
  let(:api_key) { 'fake_azure_key' }
  let(:token_url) { "https://#{described_class::REGION}.#{described_class::HOST}#{described_class::SCOPED_TOKEN_URL}" }

  before do
    allow(Rails.application.config).to receive(:azure_speech_service_api_key).and_return(api_key)
  end

  describe '#scoped_token' do
    context 'when the request is successful' do
      let(:token) { 'fake_token' }

      before do
        stub_request(:post, token_url)
          .to_return(
            status: 200,
            body: token.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches the token and caches it' do
        expect(client.scoped_token).to eq(
          expires_in: described_class::DEFAULT_EXPIRES_IN,
          token:
        )
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, token_url)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns a nil token' do
        expect(client.scoped_token).to be_nil
      end
    end
  end
end
