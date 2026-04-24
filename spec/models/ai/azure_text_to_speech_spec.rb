describe AI::AzureTextToSpeech do
  let(:api_key) { 'fake_azure_key' }
  let(:region) { 'eastus' }
  let(:ssml) do
    <<-XML
    <speak version='1.0' xml:lang='en-US'>
      <voice xml:lang='en-US' xml:gender='Female' name='en-US-JennyMultilingualNeural'>
        I'm excited to try text to speech!
      </voice>
    </speak>
    XML
  end

  before do
    allow(Rails.application.config).to receive(:azure_speech_service_api_key).and_return(api_key)
    allow(Rails.application.config).to receive(:azure_speech_service_region).and_return(region)
  end

  describe '#list_voices' do
    let(:uri) { "https://#{region}.tts.speech.microsoft.com/cognitiveservices/voices/list" }

    context 'when the request is successful' do
      let(:response_body) do
        [{ 'ShortName' => 'en-US-JennyMultilingualNeural' }].to_json
      end

      before do
        stub_request(:get, uri).with(
          headers: {
            'Accept' => 'application/json'
          }
        ).to_return(status: 200, body: response_body)
      end

      it 'returns the list of voices' do
        expect(described_class.new.list_voices).to eq(response_body)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, uri).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises a server error' do
        expect { described_class.new.list_voices }.to raise_error(RuntimeError, /Server error/)
      end
    end
  end

  describe '#generate_from_ssml' do
    let(:uri) { "https://#{region}.tts.speech.microsoft.com/cognitiveservices/v1" }
    let(:response_body) { 'fake_audio_data' }

    context 'when the request is successful' do
      before do
        stub_request(:post, uri).with(
          headers: {
            'Content-Type' => 'application/ssml+xml'
          }
        ).to_return(status: 200, body: response_body)
      end

      it 'returns the audio data for the input text' do
        result = described_class.new.generate_from_ssml(ssml)
          expect(result).to eq(response_body)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, uri)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises a server error' do
        expect { described_class.new.generate_from_ssml(ssml) }.to raise_error(RuntimeError, /Server error/)
      end
    end
  end
end
