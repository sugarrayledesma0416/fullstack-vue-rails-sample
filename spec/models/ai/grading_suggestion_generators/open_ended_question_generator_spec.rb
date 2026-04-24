describe AI::GradingSuggestionGenerators::OpenEndedQuestionGenerator do
  let(:attempt) { create(:attempt_submitted, activity:) }
  let(:prompt) { create(:ai_grading_suggestion_prompt) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input) }
  let(:activity) { create(:activity, activity_type: 'open_ended') }

  let(:generator) do
    described_class.new(
      attempt:,
      grading_suggestion_input:,
      job_id: job.id,
      prompt:,
      question_label: question.label
    )
  end

  let(:job) do
    create(:ai_grading_suggestion_job, attempt:, question_label: question.label)
  end

  let(:question_generator) do
    instance_double(
      AI::GradingSuggestionGenerators::QuestionGenerator,
      generate: true
    )
  end

  describe '#generate' do
    let(:question) do
      MaestroActivityEngine::ActivityContent::OpenEnded::Item.new(
        rank: 1
      )
    end
    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::OpenEndedContent,
        questions: [question]
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
      allow(AI::GradingSuggestionGenerators::QuestionGenerator)
        .to receive(:new)
        .with(
          attempt:,
          grading_suggestion_input:,
          job_id: job.id,
          prompt:,
          question_label: question.label,
          student_submission: 'blah'
        ).and_return(question_generator)
    end

    context 'when the attempt has a response for a question,' do
      before do
        attempt_results.add(
          auto_graded: false,
          correctness: 'pending',
          label: question.label,
          points_earned: 0,
          points_possible: 10,
          submitted: true,
          response: 'blah'
        )
      end

      it 'adds an open ended question generator job to the sidekiq queue for that question' do
        generator.generate

        expect(question_generator).to have_received(:generate)
      end
    end

    context 'when the attempt has no response for a question,' do
      it 'does not add an open ended question generator job to the sidekiq queue for that question' do
        generator.generate

        expect(question_generator).not_to have_received(:generate)
      end
    end
  end
end
