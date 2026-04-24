describe AI::GradingSuggestionGenerators::OpenEndedActivityGenerator do
  let(:attempt) { create(:attempt_submitted, activity:) }
  let(:prompt) { create(:ai_grading_suggestion_prompt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input) }
  let(:generator) { described_class.new(attempt:, grading_suggestion_input:, prompt:) }
  let(:activity) { create(:activity, activity_type: 'open_ended') }
  let(:job) { create(:grading_suggestion_job, attempt:, question_label: question_1.label) }
  let(:open_ended_question_generator_worker_class) do
    AI::GradingSuggestionGenerators::OpenEndedQuestionGeneratorWorker
  end

  describe '#generate' do
    let(:question_1) do
      MaestroActivityEngine::ActivityContent::OpenEnded::Item.new(
        rank: 1
      )
    end
    let(:question_2) do
      MaestroActivityEngine::ActivityContent::OpenEnded::Item.new(
        rank: 2
      )
    end
    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::OpenEndedContent,
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
      allow(open_ended_question_generator_worker_class).to receive(:perform_async)
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

      it 'creates a grading suggestion job for each question' do
        expect { generator.generate }.to change(AI::GradingSuggestionJob, :count).by(2)
      end

      it 'adds an open ended question generator job to the sidekiq queue for that question' do
        generator.generate

        job = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_1.label
        )

        expect(open_ended_question_generator_worker_class)
          .to have_received(:perform_async)
          .with(attempt.id, question_1.label, prompt.id, job.id, grading_suggestion_input.id)
      end
    end

    context 'when the attempt has no response for a question,' do
      it 'creates an AI::GradingSuggestionJob record with status failed_empty_response' do
        generator.generate

        job_question_1 = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_1.label
        )
        expect(job_question_1).to have_attributes(status: 'failed_empty_response')

        job_question_2 = AI::GradingSuggestionJob.find_by(
          attempt_id: attempt.id, question_label: question_2.label
        )
        expect(job_question_2).to have_attributes(status: 'failed_empty_response')
      end

      it 'does not add an open ended question generator job to the sidekiq queue for that question' do
        generator.generate

        expect(open_ended_question_generator_worker_class)
          .not_to have_received(:perform_async)
      end
    end
  end
end
