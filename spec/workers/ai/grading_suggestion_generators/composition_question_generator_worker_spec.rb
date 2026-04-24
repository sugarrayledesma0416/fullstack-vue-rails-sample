describe AI::GradingSuggestionGenerators::CompositionQuestionGeneratorWorker do
  let(:attempt) { create(:attempt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input, attempt:) }
  let(:prompt) { create(:ai_grading_suggestion_prompt) }
  let(:question_label) { 'question_01' }
  let(:job) { create(:ai_grading_suggestion_job, attempt:, question_label:) }

  let(:generator) do
    instance_double(AI::GradingSuggestionGenerators::CompositionQuestionGenerator)
  end

  before do
    allow(AI::GradingSuggestionGenerators::CompositionQuestionGenerator)
      .to receive(:new)
      .with(
        question_label:,
        attempt:,
        grading_suggestion_input:,
        prompt:,
        job_id: job.id
      ).and_return(generator)
    allow(generator).to receive(:generate)
  end

  describe '#perform' do
    it 'generates a grading suggestion for the question,' do
      described_class.new.perform(
        attempt.id,
        question_label,
        prompt.id,
        job.id,
        grading_suggestion_input.id
      )

      expect(generator).to have_received(:generate)
    end
  end
end
