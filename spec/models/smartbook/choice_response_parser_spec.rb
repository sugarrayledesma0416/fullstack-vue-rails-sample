describe Smartbook::ChoiceResponseParser do
  # rubocop:disable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:disable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  let(:multiple_choice_result) { {:object=>{:id=>"52352/interaction/2dfeeab6f1e3d6844900c13116ed0244", :objectType=>"Activity", :definition=>{:type=>"http://adlnet.gov/expapi/activities/cmi.interaction", :description=>{:en=>"17. ¿Tú o usted?. Decide.&nbsp;Would you use&nbsp;tú&nbsp;or&nbsp;usted&nbsp;to speak to the following people?."}, :interactionType=>"choice", :correctResponsesPattern=>["5ba89c0edf88fa426bd1a660230620d7[,]ac9dc7926d8933019824f1d1d5d09220[,]9d53d67d82f9456c6d1f2710214ef16b[,]a814e4eb62ffee42fe308f65c7ffd996[,]a983f9b57868564e47b307eee8ed4b33"], :choices=>[{:id=>"6ce65e8897b6117933f0e7a301a9d719", :description=>{:en=>"tú."}}, {:id=>"5ba89c0edf88fa426bd1a660230620d7", :description=>{:en=>"usted."}}, {:id=>"03f93d06ab1ed3b9f3c22256184e5c12", :description=>{:en=>"tú."}}, {:id=>"ac9dc7926d8933019824f1d1d5d09220", :description=>{:en=>"usted."}}, {:id=>"9d53d67d82f9456c6d1f2710214ef16b", :description=>{:en=>"tú."}}, {:id=>"435635745141be564b38ab9e2f85c057", :description=>{:en=>"usted."}}, {:id=>"a814e4eb62ffee42fe308f65c7ffd996", :description=>{:en=>"tú."}}, {:id=>"abfe6331c22f6f11b2be261606c61bb1", :description=>{:en=>"usted."}}, {:id=>"eddc810a2ff2dd446876702e92d8c9d3", :description=>{:en=>"tú."}}, {:id=>"a983f9b57868564e47b307eee8ed4b33", :description=>{:en=>"usted."}}]}}, :result=>{:success=>false, :response=>"5ba89c0edf88fa426bd1a660230620d7[,]ac9dc7926d8933019824f1d1d5d09220[,]a814e4eb62ffee42fe308f65c7ffd996[,]a983f9b57868564e47b307eee8ed4b33", :extensions=>{:"http://scorm.com/extensions/usa-data"=>{:iconCollectionQuiz=>"usa", :competenceUsa=>"1.2,To identify yourself and others", :analytics=>{:Product=>"SB", :Level=>"HS1", :Unit=>"U1", :Activity=>"017", :Section=>"D1G", :"Modes of Communication"=>"Interpretive Reading", :"Learning Objectives"=>"To identify yourself and others", :Standards=>"1.2"}, :correctResponsesPattern=>"1.[.]usted[,]2.[.]usted[,]3.[.]tú[,]4.[.]tú[,]5.[.]usted", :response=>"1.[.]usted[,]2.[.]usted[,]4.[.]tú[,]5.[.]usted"}}, :score=>{:raw=>90, :min=>0, :max=>100}}, :context=>{:contextActivities=>{:parent=>[{:id=>"52352", :objectType=>"Activity"}]}}, :id=>"949fcc68-1d56-4fe9-8ff2-c4f8e22f7446", :verb=>"http://adlnet.gov/expapi/verbs/answered", :stored=>"2019-01-29T21:06:31Z", :timestamp=>"2019-01-29T21:06:30Z"} }
  let(:multiple_choice_student_response) { "1. usted 2. usted 4. tú 5. usted" }
  let(:multiple_choice_correct_response) { "1. usted 2. usted 3. tú 4. tú 5. usted" }
  let(:response_parser) { described_class.new(Xapi::Statement.new(multiple_choice_result)) }

  # rubocop:enable Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces,
  # rubocop:enable Style/StringLiterals, Layout/SpaceAroundOperators, Layout/LineLength
  describe '#formatted_correct_response' do
    it 'returns a correct response string' do
      expect(response_parser.formatted_correct_response).to eql multiple_choice_correct_response
    end
  end

  describe '#formatted_student_response' do
    it 'returns a formatted string' do
      expect(response_parser.formatted_student_response).to eql multiple_choice_student_response
    end
  end
end
