describe Smartbook::AudioRecordingResponseParser do
  let(:audio_recording_result) do
    {
      object: {
        type: 'http://adlnet.gov/expapi/activities/cmi.interaction',
        id: '290654/interaction/a4f92e20b3563bc18c17f99283b9b449',
        description: { en: '8b. Describe what you did yesterday.' },
        interactionType: 'other',
        correctResponsesPattern: ['']
      },
      context: {
        contextActivities: {
          parent: [{ id: '247967', objectType: 'Activity' }]
        }
      },
      verb: {
        id: 'http://adlnet.gov/expapi/verbs/answered',
        display: { 'en-GB': 'answered', 'en-US': 'answered', 'es': 'respondió', 'und': 'answered' }
      },
      result: {
        success: false,
        response: '//santillanausa.s3.amazonaws.com/VR_SBHS1/HS1UP002bCCP1/201926392937868.wav',
        extensions: {
          'http://scorm.com/extensions/usa-data': {
            iconCollectionQuiz: 'usa',
            'competenceUsa': 'Interpersonal Speaking, Spell and pronounce Spanish words',
            'analytics': {
              'Product': 'SB',
              'Level': 'HS1',
              'Unit': 'UP',
              'Activity': '008b',
              'Section': 'CCP1',
              'Modes of Communication': 'Interpersonal Speaking',
              'Learning Objectives': 'Spell and pronounce Spanish words',
              'Standards': '1.1, 1.2, 4.1'
            },
            response: '//santillanausa.s3.amazonaws.com/VR_SBHS1/HS1UP002bCCP1/201926392937868.wav'
          }
        }
      },
      timestamp: '2019-01-29T21:06:30Z'
    }
  end
  let(:response_parser) { described_class.new(Xapi::Statement.new(audio_recording_result)) }

  describe '#instructor_gradable?' do
    it 'returns true' do
      expect(response_parser).to be_instructor_gradable
    end
  end

  describe '#formatted_correct_response' do
    it 'returns a correct response string' do
      expect { response_parser.formatted_correct_response }.to raise_error(NotImplementedError)
    end
  end

  describe '#formatted_student_response' do
    it 'returns a formatted string' do
      expect(response_parser.formatted_student_response).to eq(
        '//santillanausa.s3.amazonaws.com/VR_SBHS1/HS1UP002bCCP1/201926392937868.wav'
      )
    end
  end
end
