describe AI::GradingSuggestionGenerators::CompositionActivityGenerator do
  let(:attempt) { create(:attempt_submitted, activity:) }
  let(:prompt) { create(:ai_grading_suggestion_prompt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input) }
  let(:generator) { described_class.new(attempt:, prompt:, grading_suggestion_input:) }
  let(:activity) { create(:activity, activity_type: 'composition') }
  let(:composition_question_generator_worker_class) do
    AI::GradingSuggestionGenerators::CompositionQuestionGeneratorWorker
  end

  describe '#generate' do
    let(:question_1) do
      MaestroActivityEngine::ActivityContent::Composition::Item.new(
        rank: 1
      )
    end
    let(:question_2) do
      MaestroActivityEngine::ActivityContent::Composition::Item.new(
        rank: 2
      )
    end
    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::CompositionContent,
        questions: [question_1, question_2]
      )
    end
    let(:attempt_results) do
      MaestroActivityEngine::ActivityContent::Results.new(
        activity.content_object
      )
    end

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(attempt).to receive(:results).and_return(attempt_results)
      allow(composition_question_generator_worker_class).to receive(:perform_async)
    end

    context 'when the attempt has a response for a question,' do
      before do
        attempt_results.add(
          auto_graded: false,
          correctness: 'pending',
          label: question_1.label,
          points_earned: 0,
          points_possible: 10,
          submitted: true,
          response: 'blah'
        )
      end

      it 'creates an AI::GradingSuggestionJob record' do
        generator.generate

        job = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_1.label
        )
        expect(job).to have_attributes(status: 'in_progress')
      end

      it 'adds a composition question generator job to the sidekiq queue for that question' do
        generator.generate

        job = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_1.label
        )

        expect(composition_question_generator_worker_class)
          .to have_received(:perform_async)
          .with(attempt.id, question_1.label, prompt.id, job.id, grading_suggestion_input.id)
      end
    end

    context 'when the attempt has no response for a question,' do
      it 'creates an AI::GradingSuggestionJob record with status failed_empty_response' do
        generator.generate

        job = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_1.label
        )
        expect(job).to have_attributes(status: 'failed_empty_response')
      end

      it 'does not add a composition question generator job to the sidekiq queue for that question' do
        generator.generate

        expect(composition_question_generator_worker_class)
          .not_to have_received(:perform_async)
      end
    end
  end
end
