describe AI::AzureSpeechRecognizer do
  describe '#recognize' do
    let(:tempfile) { Tempfile.new(['fake', '.wav']) }
    let(:filename) { tempfile.path }
    let(:sample_rate) { 16_000 }
    let(:language) { 'es-MX' }
    let(:reference_text) { 'uno, dos, tres' }
    let(:recognizer) { described_class.new(filename:, sample_rate:, language:, reference_text:) }
    let(:api_key) { 'fake_azure_key' }
    let(:region) { 'eastus' }
    let(:uri) { "https://#{region}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?format=detailed&language=#{language}" }

    before do
      allow(Rails.application.config).to receive(:azure_speech_service_api_key).and_return(api_key)
      allow(Rails.application.config).to receive(:azure_speech_service_region).and_return(region)
    end

    after do
      tempfile.close
      tempfile.unlink
    end

    context 'when the request is successful' do
      let(:response_body) do
        { 'RecognitionStatus' => 'Success', 'DisplayText' => 'uno dos tres' }.to_json
      end

      before do
        stub_request(:post, uri)
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => "audio/wav; codecs=audio/pcm; samplerate=#{sample_rate}"
            }
          ).to_return(status: 200, body: response_body)
      end

      it 'returns the recognized text' do
        expect(recognizer.recognize).to eq(response_body)
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, uri)
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises a server error' do
        expect { recognizer.recognize }.to raise_error(RuntimeError, /Server error/)
      end
    end
  end
end
