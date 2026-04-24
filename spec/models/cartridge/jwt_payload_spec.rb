describe Cartridge::JWTPayload do
  let(:payload) do
    {
      consumer_guid: SecureRandom.uuid,
      context_id: 'lms_context_id',
      context_label: 'lms_context_label',
      context_title: 'lms_context_title',
      launch_presentation_return_url: 'www.lms.com/presentation_return',
      lis_outcome_service_url: 'www.lms.com/outcome_service',
      lis_result_sourcedid: 'lms_result_cell'
    }
  end
  let(:decoding_array) { ["maestro", "test", "secret"] }
  let(:decoding_arrays) { [["password1", "password2"], ["password3", "secret"], ["password4", "password5"]] }

  def encode(password)
    JWT.encode payload, password, 'HS256'
  end

  describe '.decode' do
    context 'when values used to decode the payload are contained in an array' do
      it 'succeeds' do
        allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(decoding_array)
        encoded_params = encode('secret')
        decoded_params = described_class.decode(encoded_params)
        expect(decoded_params.symbolize_keys).to include(payload)
      end
    end

    context 'when values used to decode the payload are contained in arrays of arrays' do
      it 'succeeds' do
        allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(decoding_arrays)
        encoded_params = encode('secret')
        decoded_params = described_class.decode(encoded_params)
        expect(decoded_params.symbolize_keys).to include(payload)
      end
    end

    context 'when correct value to decode the payload is missing' do
      it 'succeeds' do
        allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(decoding_arrays)
        encoded_params = encode('nonsense')
        decoded_params = described_class.decode(encoded_params)
        expect(decoded_params).to be_empty
      end
    end
  end
end