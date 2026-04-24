describe Smartbook::Response do
  let(:interaction_id) { 487_203 }
  let(:interaction_type) { 'long-fill-in' }
  let(:learning_module_id) { "https://netexlearning.com/#{interaction_id}" }
  let(:object_type) { Xapi::Statement::OBJECT_TYPE_ACTIVITY }
  let(:new_statement_timestamp) { Time.now.utc }

  def create_statement(attrs = {})
    analytics = {
      # Product: 'SB',
      # Level: 'HS1',
      # Unit: 'U1',
      Activity: '042',
      # Section: 'D1C',
      # 'Modes of Communication': 'Interpretive Reading',
      # 'Learning Objectives': 'To identify yourself and others',
      # Standards: '1.2'
    }
    params = {
      id: SecureRandom.uuid,
      timestamp: new_statement_timestamp,
      verb: Xapi::VERB_ANSWERED,
      result: {
        extensions: {
          :'http://scorm.com/extensions/usa-data' => {
            # iconCollectionQuiz: 'usa',
            # competenceUsa: '1.2,To identify yourself and others',
            analytics: analytics
          }
        }
      },
      object: {
        definition: { interactionType: interaction_type },
        objectType: object_type,
        id: learning_module_id
      },
      stored: Time.now.utc
    }.deep_merge(attrs)
    Xapi::Statement.new(params)
  end

  describe '#subactivity_id' do
    it 'returns the interaction_id prefixed by "int_"' do
      response = described_class.new(create_statement)
      expect(response.subactivity_id).to eq("int_#{interaction_id}")
    end
  end

  describe '#interaction_id' do
    it 'returns the last element of the object id separated by slashes' do
      response = described_class.new(create_statement)
      expect(response.interaction_id).to eq(interaction_id.to_s)
    end
  end

  describe '#label' do
    it 'returns the activity number from the analytics,' \
       ' prefixed by question_' do
      response = described_class.new(create_statement)
      expect(response.label).to eq('question_42')
    end
  end

  describe '#answered' do
    it 'returns true when the statement verb is answered' do
      statement = create_statement(
        verb: Xapi::VERB_ANSWERED
      )
      response = described_class.new(statement)
      expect(response).to be_answered
    end

    it 'returns false when the statement verb is not answered' do
      [
        Xapi::VERB_INITIALIZED
      ].each do |verb|
        statement = create_statement(
          verb: verb
        )
        response = described_class.new(statement)
        expect(response).not_to be_answered
      end
    end
  end

  describe '#partial_name' do
    it 'returns the string "smartbook"' do
      response = described_class.new(create_statement)
      expect(response.partial_name).to eq 'smartbook'
    end
  end

  describe '#subactivity_type' do
    it 'returns the interaction type from the definition' do
      response = described_class.new(create_statement)
      expect(response.subactivity_type).to eq(interaction_type)
    end
  end

  describe '#instructor_gradable?' do
    it 'is false when the statement verb is not answered' do
      statement = create_statement(
        verb: Xapi::VERB_INITIALIZED
      )
      response = described_class.new(statement)
      expect(response).not_to be_instructor_gradable
    end

    context 'when the statement verb is answered,' do
      let(:parser_klass) { Smartbook::LongFillInResponseParser }
      let(:parser) { instance_double(parser_klass) }

      before do
        allow(parser_klass).to receive(:new).and_return(parser)
      end

      it 'is true when the response parser is instructor gradable' do
        allow(parser).to receive(:instructor_gradable?).and_return(true)
        response = described_class.new(create_statement)
        expect(response).to be_instructor_gradable
      end

      it 'is false when the response parser is not instructor gradable' do
        allow(parser).to receive(:instructor_gradable?).and_return(false)
        response = described_class.new(create_statement)
        expect(response).not_to be_instructor_gradable
      end
    end
  end

  describe '#auto_graded?' do
    it 'is false when the statement verb is not answered' do
      statement = create_statement(
        verb: Xapi::VERB_INITIALIZED
      )
      response = described_class.new(statement)
      expect(response).not_to be_auto_graded
    end

    context 'when the statement verb is answered,' do
      let(:parser_klass) { Smartbook::LongFillInResponseParser }
      let(:parser) { instance_double(parser_klass) }

      before do
        allow(parser_klass).to receive(:new).and_return(parser)
      end

      it 'is false when the response parser is instructor gradable' do
        allow(parser).to receive(:instructor_gradable?).and_return(true)
        response = described_class.new(create_statement)
        expect(response).not_to be_auto_graded
      end

      it 'is true when the response parser is not instructor gradable' do
        allow(parser).to receive(:instructor_gradable?).and_return(false)
        response = described_class.new(create_statement)
        expect(response).to be_auto_graded
      end
    end
  end

  describe '#response_parser' do
    it 'returns nil when the statement verb is not answered' do
      [
        Xapi::VERB_INITIALIZED
      ].each do |verb|
        statement = create_statement(
          verb: verb
        )
        response = described_class.new(statement)
        expect(response.response_parser).to be_nil
      end
    end

    context 'when the statement verb is answered,' do
      let(:verb) { Xapi::VERB_ANSWERED }

      it 'returns an instance of LongFillInResponseParser when ' \
         'subactivity_type is "long-fill-in"' do
        statement = create_statement(
          object: {
            definition: { interactionType: 'long-fill-in' }
          },
          verb: verb
        )
        response = described_class.new(statement)
        expect(response.response_parser).to be_a(Smartbook::LongFillInResponseParser)
      end

      it 'returns an instance of ChoiceResponseParser when subactivity_type' \
         'is "choice"' do
        statement = create_statement(
          object: {
            definition: { interactionType: 'choice' }
          },
          verb: verb
        )
        response = described_class.new(statement)
        expect(response.response_parser).to be_a(Smartbook::ChoiceResponseParser)
      end

      it 'returns an instance of MatchingResponseParser when subactivity_type is "matching"' do
        statement = create_statement(
          object: {
            definition: { interactionType: 'matching' }
          },
          verb: verb
        )
        response = described_class.new(statement)
        expect(response.response_parser).to be_a(Smartbook::MatchingResponseParser)
      end

      it 'raises a NotImplementedError with an unknown subactivity_type' do
        unknown_type = 'unknown'
        statement = create_statement(
          object: {
            definition: { interactionType: unknown_type }
          },
          verb: verb
        )
        response = described_class.new(statement)
        expect { response.response_parser }.to raise_error(
          NotImplementedError,
          "unknown subactivity_type: '#{unknown_type}'"
        )
      end

      context 'when the response is for a drawing activity,' do
        it 'returns an instance of DrawingResponseParser' do
          image_data = [1, 2, 3, 4]
          image_base64 = Base64.encode64(image_data.pack('C*'))
          statement = create_statement(
            object: {
              definition: { interactionType: 'other' }
            },
            result: {
              extensions: {
                'http://scorm.com/extensions/tcdraw-data' => {
                  image: "data:image/png;base64,#{image_base64}"
                }
              }
            },
            verb: verb
          )
          response = described_class.new(statement)
          expect(response.response_parser).to be_a(
            Smartbook::DrawingResponseParser
          )
        end
      end

      context 'when subactivity_type is "other",' do
        let(:subactivity_type) { 'other' }

        it 'raises a NotImplementedError when there is no response' \
           'in the results' do
          statement = create_statement(
            object: {
              definition: { interactionType: subactivity_type }
            },
            verb: verb
          )
          response = described_class.new(statement)
          expect { response.response_parser }.to raise_error(NotImplementedError)
        end

        it 'raises a NotImplementedError when the response in the results' \
          'does not start with the recording prefix' do
          statement = create_statement(
            object: {
              definition: { interactionType: subactivity_type }
            },
            result: { response: 'blabla' },
            verb: verb
          )
          response = described_class.new(statement)
          expect { response.response_parser }.to raise_error(NotImplementedError)
        end

        it 'returns an instance of AudioRecordingResponseParser when' \
           'the response in the results starts whith the recording prefix' do
          statement = create_statement(
            object: {
              definition: { interactionType: subactivity_type }
            },
            result: {
              response: Rails.application.config.smartbook_recording_endpoint + 'blabla'
            },
            verb: verb
          )

          expect(described_class.new(statement).response_parser).to be_a(
            Smartbook::AudioRecordingResponseParser
          )
        end

        it 'returns an instance of AudioRecordingResponseParser when' \
           'the response in the results starts whith the santillana s3 ' \
           'bucket recording prefix' do
          statement = create_statement(
            object: {
              definition: { interactionType: subactivity_type }
            },
            result: {
              response: described_class::SANTILLANA_BUCKET_PREFIX + 'blabla'
            },
            verb: verb
          )

          expect(described_class.new(statement).response_parser).to be_a(
            Smartbook::AudioRecordingResponseParser
          )
        end
      end
    end
  end
end
