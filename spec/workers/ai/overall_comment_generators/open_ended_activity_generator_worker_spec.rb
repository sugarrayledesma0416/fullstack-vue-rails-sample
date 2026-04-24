describe AI::OverallCommentGenerators::OpenEndedActivityGeneratorWorker do
  let(:attempt) { create(:attempt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input, attempt:) }
  let(:prompt) { create(:ai_overall_comment_prompt) }
  let(:generator) do
    instance_double(AI::OverallCommentGenerators::OpenEndedActivityGenerator)
  end

  before do
    allow(AI::OverallCommentGenerators::OpenEndedActivityGenerator)
      .to receive(:new)
      .with(attempt:, grading_suggestion_input:, prompt:)
      .and_return(generator)
    allow(generator).to receive(:generate)
  end

  describe '#perform' do
    it 'generates a grading suggestion for the activity,' do
      described_class.new.perform(attempt.id, prompt.id, grading_suggestion_input.id)

      expect(generator).to have_received(:generate)
    end
  end
end
