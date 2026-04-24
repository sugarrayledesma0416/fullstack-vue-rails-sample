describe Smartbook::ResponseParser do
  let(:analytics_activity) { '028' }
  let(:analytics) do
    {
      Product: 'SB',
      Level: 'HS1',
      Unit: 'U1',
      Activity: analytics_activity,
      Section: 'D1C',
      'Modes of Communication': 'Interpretive Reading',
      'Learning Objectives': 'To identify yourself and others',
      Standards: '1.2'
    }
  end
  # rubocop:disable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:disable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  let(:answered_result) { {:object=>{:id=>'https://netexlearning.com/487203/interaction/2277312942a09feaaf8af5a9f7430396', :objectType=>'Activity', :definition=>{:type=>'http://adlnet.gov/expapi/activities/cmi.interaction', :description=>{:es=>'4. Write something about yourself.'}, :interactionType=>'long-fill-in', :correctResponsesPattern=>['']}}, :result=>{:success=>false, :response=>'Me llamo Angela y soy profesor de Computadora. Soy de Mexico. Yo soy solomenta nina.', :extensions=>{:'http://scorm.com/extensions/usa-data'=>{:iconCollectionQuiz=>'usa', :competenceUsa=>'1.2,To identify yourself and others', analytics: analytics, :response=>'Me llamo Angela. Soy de Mexico.'}}}, :context=>{:contextActivities=>{:parent=>[{:id=>'https://netexlearning.com/487203', :objectType=>'Activity'}]}}, :id=>'33b26cf3-e81b-4699-ab43-9aa467df0771', :verb=>'http://adlnet.gov/expapi/verbs/answered', :stored=>'2019-01-17T20:15:46Z', :timestamp=>'2019-01-17T20:15:46Z'} }
  let(:unanswered_result) { {:object=>{:id=>'https://netexlearning.com/487203/interaction/2277312942a09feaaf8af5a9f7430396', :objectType=>'Activity'}, :context=>{:contextActivities=>{:parent=>[{:id=>'https://netexlearning.com/487203', :objectType=>'Activity'}]}}, :id=>'5b81f354-63f5-45bf-b0d9-f2d494914ac6', :verb=>'http://adlnet.gov/expapi/verbs/experienced', :stored=>'2019-01-15T15:30:57Z', :timestamp=>'2019-01-15T15:30:56Z'} }
  let(:answered_result_no_analytics) { {:object=>{:id=>'https://netexlearning.com/487203/interaction/2277312942a09feaaf8af5a9f7430396', :objectType=>'Activity', :definition=>{:type=>'http://adlnet.gov/expapi/activities/cmi.interaction', :description=>{:es=>'4. Write something about yourself.'}, :interactionType=>'long-fill-in', :correctResponsesPattern=>['']}}, :result=>{:success=>false, :response=>'Me llamo Angela y soy profesor de Computadora. Soy de Mexico. Yo soy solomenta nina.', :extensions=>{:'http://scorm.com/extensions/usa-data'=>{:iconCollectionQuiz=>'usa', :competenceUsa=>'1.2,To identify yourself and others', :response=>'Me llamo Angela. Soy de Mexico.'}}}, :context=>{:contextActivities=>{:parent=>[{:id=>'https://netexlearning.com/487203', :objectType=>'Activity'}]}}, :id=>'33b26cf3-e81b-4699-ab43-9aa467df0771', :verb=>'http://adlnet.gov/expapi/verbs/answered', :stored=>'2019-01-17T20:15:46Z', :timestamp=>'2019-01-17T20:15:46Z'} }
  # rubocop:enable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:enable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  let(:answered_statement) { Xapi::Statement.new(answered_result) }
  let(:response) { described_class.new(answered_statement) }

  let(:answered_statement_no_analytics) { Xapi::Statement.new(answered_result_no_analytics) }
  let(:no_analytics_response) { described_class.new(answered_statement_no_analytics) }

  describe '#prompt' do
    it 'returns displayable prompt of the interaction' do
      expect(response.prompt).to eql '4. Write something about yourself.'
    end
  end

  describe '#answered?' do
    context 'when result contains state of answered' do
      it 'returns true' do
        expect(response.answered?).to be true
      end
    end

    context 'when result contains any other state' do
      it 'returns false' do
        statement = Xapi::Statement.new(unanswered_result)
        expect(described_class.new(statement).answered?).to be false
      end
    end
  end

  describe '#instructor_gradable?' do
    it 'returns the default state which is false' do
      expect(response.instructor_gradable?).to be false
    end
  end

  describe '#formatted_correct_response' do
    it 'raises a NotImplementedError' do
      expect { response.formatted_correct_response }.to raise_error(NotImplementedError)
    end
  end

  describe '#formatted_student_response' do
    it 'raises a NotImplementedError' do
      expect { response.formatted_student_response }.to raise_error(NotImplementedError)
    end
  end

  describe '#question_number' do
    it 'returns the question number without the leading zeros' do
      expect(response.question_number).to eq('28')
    end

    context 'when the analytics contains the "Activity" key in Spanish' do
      let(:analytics) do
        {
          Product: 'SB',
          Level: 'HS1',
          Unit: 'U1',
          Actividad: '028',
          Section: 'D1C',
          'Modes of Communication': 'Interpretive Reading',
          'Learning Objectives': 'To identify yourself and others',
          Standards: '1.2'
        }
      end

      it 'returns the question number without the leading zeros' do
        expect(response.question_number).to eq('28')
      end
    end

    context 'when the analytics element is missing' do
      it 'returns the default question number' do
        expect(no_analytics_response.question_number).to eq('2277312942a09feaaf8af5a9f7430396')
      end
    end
  end

  describe '#primary_question_number' do
    context 'when the question number only consists of digits' do
      let(:analytics_activity) { '028' }

      it 'returns the primary question number as an integer' do
        expect(response.primary_question_number).to eq(28)
      end
    end

    context 'when the question number ends with a letter' do
      let(:analytics_activity) { '028b' }

      it 'returns the primary question number as an integer' do
        expect(response.primary_question_number).to eq(28)
      end
    end
  end

  describe '#subpart_question_number' do
    context 'when the question number only consists of digits' do
      let(:analytics_activity) { '028' }

      it 'returns nil' do
        expect(response.subpart_question_number).to be_nil
      end
    end

    context 'when the question number ends with a letter' do
      let(:analytics_activity) { '028b' }

      it 'returns the non digit part of the question number' do
        expect(response.subpart_question_number).to eq('b')
      end
    end
  end
end
