describe Smartbook::DrawingResponseParser do
  let(:image) { [1, 2, 3, 4] }
  let(:image_base64) { Base64.encode64(image.pack('C*')) }
  let(:image_data) { "data:image/png;base64,#{image_base64}" }
  let(:xapi_statement) do
    {
      object: {
        type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
        id: '294568/interaction/cc91cd4decc948d3bc2a664279b2ac1f',
        description: { es: 'DEPWBU6S3D12C. Dibújate.' },
        interactionType: 'other',
        correctResponsesPattern: ['']
      },
      context: {
        contextActivities: {
          parent: [{ id: '294568', objectType: 'Activity' }]
        }
      },
      verb: {
        id: 'http://adlnet.gov/expapi/verbs/answered',
        display: { 'en-GB': 'answered', 'en-US': 'answered', 'es': 'respondió', 'und': 'answered' }
      },
      result: {
        extensions: {
          'http://scorm.com/extensions/tcdraw-data' => {
            image: image_data
          }
        }
      },
      id: '09bc132b-6a4a-48a2-a681-68cfc09ded10',
      timestamp: '2020-06-30T09:39:23.614Z'
    }
  end
  let(:response_parser) { described_class.new(Xapi::Statement.new(xapi_statement)) }

  describe '#instructor_gradable?' do
    it 'returns true' do
      expect(response_parser).to be_instructor_gradable
    end
  end

  describe '#formatted_correct_response' do
    it 'raises a "not implemented" error' do
      expect do
        response_parser.formatted_correct_response
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#formatted_student_response' do
    it 'returns the image data as a string' do
      expect(response_parser.formatted_student_response).to eq(
        image_data
      )
    end
  end

  describe '#image_src' do
    it 'returns the image data as a string' do
      expect(response_parser.image_src).to eq(
        image_data
      )
    end
  end
end
