describe Smartbook::LongFillInResponseParser do
  # rubocop:disable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:disable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  let(:instr_graded_result) { {:object=>{:id=>"https://netexlearning.com/487203/interaction/2277312942a09feaaf8af5a9f7430396", :objectType=>"Activity", :definition=>{:type=>"http://adlnet.gov/expapi/activities/cmi.interaction", :description=>{:en=>"4. Write something about yourself."}, :interactionType=>"long-fill-in", :correctResponsesPattern=>[""]}}, :result=>{:success=>false, :response=>"Me llamo Angela y soy profesor de Computadora. Soy de Mexico. Yo soy solomenta nina.", :extensions=>{:"http://scorm.com/extensions/usa-data"=>{:iconCollectionQuiz=>"usa", :competenceUsa=>"1.2,To identify yourself and others", :analytics=>{:Product=>"SB", :Level=>"HS1", :Unit=>"U1", :Activity=>"028", :Section=>"D1C", :"Modes of Communication"=>"Interpretive Reading", :"Learning Objectives"=>"To identify yourself and others", :Standards=>"1.2"}, :response=>"Me llamo Angela. Soy de Mexico."}}}, :context=>{:contextActivities=>{:parent=>[{:id=>"https://netexlearning.com/487203", :objectType=>"Activity"}]}}, :id=>"33b26cf3-e81b-4699-ab43-9aa467df0771", :verb=>"http://adlnet.gov/expapi/verbs/answered", :stored=>"2019-01-17T20:15:46Z", :timestamp=>"2019-01-17T20:15:46Z"} }
  let(:instr_graded_student_response) { 'Me llamo Angela. Soy de Mexico.' }
  let(:unanswered_result) { {:object=>{:id=>"https://netexlearning.com/487203/#/lang/en/pag/453ffd3ab5d8ffec3a06256bb61c38e9", :objectType=>"Activity"}, :context=>{:contextActivities=>{:parent=>[{:id=>"https://netexlearning.com/487203", :objectType=>"Activity"}]}}, :id=>"5b81f354-63f5-45bf-b0d9-f2d494914ac6", :verb=>"http://adlnet.gov/expapi/verbs/experienced", :stored=>"2019-01-15T15:30:57Z", :timestamp=>"2019-01-15T15:30:56Z"} }
  let(:auto_graded_result)  { {:object=>{:id=>"https://netexlearning.com/487203/interaction/d1b2001a74ce53b2be250b1b37d1a032", :objectType=>"Activity", :definition=>{:type=>"http://adlnet.gov/expapi/activities/cmi.interaction", :description=>{:en=>"21. Soy Cristina. Completa. Cristina, the goalie for Marisa’s soccer team, wants to introduce herself to you. Complete her introduction with the correct form of the verb ser."}, :interactionType=>"long-fill-in", :correctResponsesPattern=>["soy[,]es[,]son[,]es[,]somos[,]eres"]}}, :result=>{:success=>false, :response=>"soy[,]Ella[,]son[,]es[,]eres[,]esta", :extensions=>{:"http://scorm.com/extensions/usa-data"=>{:iconCollectionQuiz=>"usa", :competenceUsa=>"1.2,To identify yourself and others", :analytics=>{:Product=>"SB", :Level=>"HS1", :Unit=>"U1", :Activity=>"021", :Section=>"D1G", :"Modes of Communication"=>"Interpretive Reading", :"Learning Objectives"=>"To identify yourself and others", :Standards=>"1.2"}, :correctResponsesPattern=>"1.[.]soy[,]2.[.]es[,]3.[.]son[,]4.[.]es[,]5.[.]somos[,]6.[.]eres", :response=>"1.[.]soy[,]2.[.]Ella[,]3.[.]son[,]4.[.]es[,]5.[.]eres[,]6.[.]esta"}}, :score=>{:raw=>50, :min=>0, :max=>100}}, :context=>{:contextActivities=>{:parent=>[{:id=>"https://netexlearning.com/487203", :objectType=>"Activity"}]}}, :id=>"a6db34aa-2e07-4684-898f-c86d38e88a99", :verb=>"http://adlnet.gov/expapi/verbs/answered", :stored=>"2019-01-23T22:03:01Z", :timestamp=>"2019-01-23T22:03:00Z"} }
  let(:auto_graded_correct_response) { '1. soy 2. es 3. son 4. es 5. somos 6. eres' }
  let(:auto_graded_student_response) { '1. soy 2. Ella 3. son 4. es 5. eres 6. esta' }
  let(:some_unanswered_student_result) { {:object=>{:id=>"52352/interaction/944426461dd690b021048c21f976e04d", :objectType=>"Activity", :definition=>{:type=>"http://adlnet.gov/expapi/activities/cmi.interaction", :description=>{:en=>"16. ¿Quiénes?. Escribe. Imagine you need to talk about these people. Write the pronoun you would use."}, :interactionType=>"long-fill-in", :correctResponsesPattern=>["ella[,]ellas[,]ellos[,]ellos[,]él[,]ellos[,]nosotros[,]ustedes||vosotros"]}}, :result=>{:success=>false, :response=>"ella[,]ellas[,]ellos[,]ellas[,]él[,]ellos", :extensions=>{:"http://scorm.com/extensions/usa-data"=>{:iconCollectionQuiz=>"usa", :competenceUsa=>"1.2, 4.1,To identify yourself and others", :analytics=>{:Product=>"SB", :Level=>"HS1", :Unit=>"U1", :Activity=>"016", :Section=>"D1G", :"Modes of Communication"=>"Interpretive Reading", :"Learning Objectives"=>"To identify yourself and others", :Standards=>"1.2, 4.1"}, :correctResponsesPattern=>"1.[.]ella[,]2.[.]ellas[,]3.[.]ellos[,]4.[.]ellos[,]5.[.]él[,]6.[.]ellos[,]7.[.]nosotros[,]8.[.]ustedes||vosotros", :response=>"1.[.]ella[,]2.[.]ellas[,]3.[.]ellos[,]4.[.]ellas[,]5.[.]él[,]6.[.]ellos[,]7.[.]undefined[,]8.[.]undefined"}}, :score=>{:raw=>62.5, :min=>0, :max=>100}}, :context=>{:contextActivities=>{:parent=>[{:id=>"52352", :objectType=>"Activity"}]}}, :id=>"ca59f291-b753-4b72-8d7b-264b8aa35751", :verb=>"http://adlnet.gov/expapi/verbs/answered", :stored=>"2019-02-01T17:19:50Z", :timestamp=>"2019-02-01T17:19:50Z"} }
  let(:some_unanswered_student_response) { '1. ella 2. ellas 3. ellos 4. ellas 5. él 6. ellos 7.   8.  ' }
  # rubocop:enable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:enable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  let(:instructor_graded_statement) { Xapi::Statement.new(instr_graded_result) }
  let(:auto_graded_statement) { Xapi::Statement.new(auto_graded_result) }
  let(:unanswered_statement) { Xapi::Statement.new(unanswered_result) }

  describe '#instructor_gradable?' do
    context 'when result contains answered state and empty correct response pattern' do
      it 'returns true' do
        expect(described_class.new(instructor_graded_statement).instructor_gradable?).to be true
      end
    end

    context 'when result contains answered state and non-empty correct response pattern' do
      it 'returns false' do
        expect(described_class.new(auto_graded_statement).instructor_gradable?).to be false
      end
    end
  end

  describe '#formatted_correct_response' do
    context 'when the response is auto-graded' do
      it 'returns a formatted string' do
        expect(described_class.new(auto_graded_statement).formatted_correct_response).to eql auto_graded_correct_response
      end
    end

    context 'when the response is instructor graded' do
      it 'returns nil' do
        expect(described_class.new(instructor_graded_statement).formatted_correct_response).to be_nil
      end
    end
  end

  describe '#formatted_student_response' do
    context 'when there is a student response' do
      it 'returns a displayable formatted string' do
        expect(described_class.new(auto_graded_statement).formatted_student_response).to eql auto_graded_student_response
      end
    end

    context 'when the response is auto-graded but contains unanswered questions ' do
      it 'returns a formatted string with blanks' do
        statement = Xapi::Statement.new(some_unanswered_student_result)
        expect(described_class.new(statement).formatted_student_response).to eql(
          some_unanswered_student_response
        )
      end
    end

    context 'when there is no student response' do
      it 'returns nil' do
        expect(described_class.new(unanswered_statement).formatted_student_response).to be_nil
      end
    end

    context 'when there is an instructor-gradable student response' do
      it 'returns the student response' do
        expect(described_class.new(instructor_graded_statement).formatted_student_response).to eql(
          instr_graded_student_response
        )
      end
    end
  end
end
