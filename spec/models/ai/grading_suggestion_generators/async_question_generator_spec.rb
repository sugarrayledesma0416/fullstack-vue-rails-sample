describe AI::GradingSuggestionGenerators::AsyncQuestionGenerator do
  let(:instructor) { create(:instructor) }
  let(:section) { create(:section, instructor:) }
  let(:attempt) { create(:attempt, activity:, section:) }
  let(:question_label) { 'question_03' }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input) }
  let(:generator) { described_class.new(attempt:, question_label:, grading_suggestion_input:) }

  let!(:prompt) do
    create(:ai_grading_suggestion_prompt, active_for_instructor_grading: true)
  end

  let(:open_ended_activity_generator_worker_class) do
    AI::GradingSuggestionGenerators::OpenEndedQuestionGeneratorWorker
  end

  let(:composition_activity_generator_worker_class) do
    AI::GradingSuggestionGenerators::CompositionQuestionGeneratorWorker
  end

  describe '#generate' do
    shared_examples 'does not add any question generator job to the sidekiq queue' do
      it 'does not add any question generator job to the sidekiq queue' do
        generator.generate

        expect(open_ended_activity_generator_worker_class)
          .not_to have_received(:perform_async)
        expect(composition_activity_generator_worker_class)
          .not_to have_received(:perform_async)
      end
    end

    before do
      allow(open_ended_activity_generator_worker_class).to receive(:perform_async)
      allow(composition_activity_generator_worker_class).to receive(:perform_async)
      # Disable AI Core syncing for tests to use factory-created prompts
      allow(AI::GradingSuggestionPrompt).to receive(:using_ai_core_source?).and_return(false)
    end

    context 'when the attempt is for an open ended activity,' do
      let(:activity) { create(:activity, activity_type: 'open_ended') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::OpenEndedContent)
      end
      let(:job) { instance_spy(AI::GradingSuggestionJob, id: 123) }

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(true)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(false)
        allow(activity).to receive(:content_object).and_return(content_object)
        allow(AI::GradingSuggestionJob).to receive(:find_or_initialize_by).and_return(job)
        # Ensure the generator uses the factory-created prompt
        allow_any_instance_of(described_class).to receive(:prompt).and_return(prompt)
      end

      it 'creates a job and adds an open ended question generator job to the sidekiq queue' do
        generator.generate

        expect(AI::GradingSuggestionJob).to have_received(:find_or_initialize_by).with(
          attempt_id: attempt.id,
          question_label: question_label
        )
        expect(job).to have_received(:save!)
        expect(open_ended_activity_generator_worker_class)
          .to have_received(:perform_async)
          .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
      end
    end

    context 'when the attempt is for a composition activity,' do
      let(:activity) { create(:activity, activity_type: 'composition') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::CompositionContent)
      end
      let(:job) { instance_spy(AI::GradingSuggestionJob, id: 123) }

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(false)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(true)
        allow(activity).to receive(:content_object).and_return(content_object)
        allow(AI::GradingSuggestionJob).to receive(:find_or_initialize_by).and_return(job)
        # Ensure the generator uses the factory-created prompt
        allow_any_instance_of(described_class).to receive(:prompt).and_return(prompt)
      end

      it 'creates a job and adds a composition question generator job to the sidekiq queue' do
        generator.generate

        expect(AI::GradingSuggestionJob).to have_received(:find_or_initialize_by).with(
          attempt_id: attempt.id,
          question_label: question_label
        )
        expect(job).to have_received(:save!)
        expect(composition_activity_generator_worker_class)
          .to have_received(:perform_async)
          .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
      end
    end

    context 'when the attempt is for a multi type activity,' do
      let(:activity) { create(:activity, activity_type: 'multi_type') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::CompositionContent)
      end
      let(:job) { instance_spy(AI::GradingSuggestionJob, id: 123) }

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(true)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(true)
        allow(activity).to receive(:content_object).and_return(content_object)
        allow(AI::GradingSuggestionJob).to receive(:find_or_initialize_by).and_return(job)
        # Ensure the generator uses the factory-created prompt
        allow_any_instance_of(described_class).to receive(:prompt).and_return(prompt)
      end

      context 'when the activity contains an open ended activity,' do
        it 'creates a job and adds an open ended question generator job to the sidekiq queue' do
          generator.generate

          expect(AI::GradingSuggestionJob).to have_received(:find_or_initialize_by).with(
            attempt_id: attempt.id,
            question_label: question_label
          ).at_least(:once)
          expect(job).to have_received(:save!).at_least(:once)
          expect(open_ended_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
        end
      end

      context 'when the activity does not contain any open ended activity,' do
        it 'does not add any open ended question generator job to the sidekiq queue' do
          allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(false)

          generator.generate

          expect(open_ended_activity_generator_worker_class)
            .not_to have_received(:perform_async)
        end
      end

      context 'when the activity contains a composition activity,' do
        it 'creates a job and adds a composition question generator job to the sidekiq queue' do
          generator.generate

          expect(AI::GradingSuggestionJob).to have_received(:find_or_initialize_by).with(
            attempt_id: attempt.id,
            question_label: question_label
          ).at_least(:once)
          expect(job).to have_received(:save!).at_least(:once)
          expect(composition_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
        end
      end

      context 'when the activity does not contain any composition activity,' do
        it 'does not add any composition question generator job to the sidekiq queue' do
          allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(false)

          generator.generate

          expect(composition_activity_generator_worker_class)
            .not_to have_received(:perform_async)
        end
      end

      context 'when the activity contains an open ended activity and a composition activity,' do
        it 'creates jobs and adds both question generator jobs to the sidekiq queue' do
          generator.generate

          expect(AI::GradingSuggestionJob).to have_received(:find_or_initialize_by).with(
            attempt_id: attempt.id,
            question_label: question_label
          ).at_least(:once)
          expect(job).to have_received(:save!).at_least(:once)
          expect(open_ended_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
          expect(composition_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, job.id, grading_suggestion_input.id)
        end
      end
    end

    context 'when the attempt is for a different activity type,' do
      let(:activity) { create(:activity) }

      it_behaves_like 'does not add any question generator job to the sidekiq queue'
    end
  end
end
