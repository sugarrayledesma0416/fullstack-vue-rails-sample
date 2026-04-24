describe AI::OverallCommentGenerators::OpenEndedQuestionGeneratorWorker do
  let(:attempt) { create(:attempt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input, attempt:) }
  let(:prompt) { create(:ai_overall_comment_prompt) }
  let(:question_label) { 'question_01' }
  let(:generator) do
    instance_double(AI::OverallCommentGenerators::OpenEndedQuestionGenerator)
  end

  before do
    allow(AI::OverallCommentGenerators::OpenEndedQuestionGenerator)
      .to receive(:new)
      .with(attempt:, grading_suggestion_input:, prompt:, question_label:)
      .and_return(generator)
    allow(generator).to receive(:generate)
  end

  describe '#perform' do
    it 'generates a grading suggestion for the question,' do
      described_class.new.perform(attempt.id, question_label, prompt.id, grading_suggestion_input.id)

      expect(generator).to have_received(:generate)
    end
  end
end
