describe AI::OverallCommentGenerators::AsyncQuestionGenerator do
  let(:instructor) { create(:instructor) }
  let(:section) { create(:section, instructor:) }
  let(:attempt) { create(:attempt, activity:, section:) }
  let(:grading_suggestion_input) { create(:ai_grading_suggestion_input, attempt:) }
  let(:question_label) { 'question_03' }
  let(:generator) { described_class.new(attempt:, grading_suggestion_input:, question_label:) }

  let!(:prompt) do
    create(:ai_overall_comment_prompt, active_for_instructor_grading: true)
  end

  let(:open_ended_activity_generator_worker_class) do
    AI::OverallCommentGenerators::OpenEndedQuestionGeneratorWorker
  end

  let(:composition_activity_generator_worker_class) do
    AI::OverallCommentGenerators::CompositionQuestionGeneratorWorker
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
      allow(AI::OverallCommentPrompt).to receive(:using_ai_core_source?).and_return(false)
      # Ensure the generator uses the factory-created prompt
      allow_any_instance_of(described_class).to receive(:prompt).and_return(prompt)
    end

    context 'when the attempt is for an open ended activity,' do
      let(:activity) { create(:activity, activity_type: 'open_ended') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::OpenEndedContent)
      end

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(true)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(false)
        allow(activity).to receive(:content_object).and_return(content_object)
      end

      it 'adds an open ended question generator job to the sidekiq queue' do
        generator.generate

        expect(open_ended_activity_generator_worker_class)
          .to have_received(:perform_async)
      end
    end

    context 'when the attempt is for a composition activity,' do
      let(:activity) { create(:activity, activity_type: 'composition') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::CompositionContent)
      end

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(false)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(true)
        allow(activity).to receive(:content_object).and_return(content_object)
      end

      it 'adds a composition question generator job to the sidekiq queue' do
        generator.generate

        expect(composition_activity_generator_worker_class)
          .to have_received(:perform_async)
          .with(attempt.id, question_label, prompt.id, grading_suggestion_input.id)
      end
    end

    context 'when the attempt is for a multi type activity,' do
      let(:activity) { create(:activity, activity_type: 'multi_type') }
      let(:content_object) do
        instance_double(MaestroActivityEngine::ActivityContent::CompositionContent)
      end

      before do
        allow(content_object).to receive(:includes_activity_type?).with('open_ended').and_return(true)
        allow(content_object).to receive(:includes_activity_type?).with('composition').and_return(true)
        allow(activity).to receive(:content_object).and_return(content_object)
      end

      context 'when the activity contains an open ended activity,' do
        it 'adds an open ended question generator job to the sidekiq queue' do
          generator.generate

          expect(open_ended_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, grading_suggestion_input.id)
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
        it 'adds a composition question generator job to the sidekiq queue' do
          generator.generate

          expect(composition_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, grading_suggestion_input.id)
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
        it 'adds an open ended question generator job to the sidekiq queue' do
          generator.generate

          expect(open_ended_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, grading_suggestion_input.id)
        end

        it 'adds a composition question generator job to the sidekiq queue' do
          generator.generate

          expect(composition_activity_generator_worker_class)
            .to have_received(:perform_async)
            .with(attempt.id, question_label, prompt.id, grading_suggestion_input.id)
        end
      end
    end

    context 'when the attempt is for a different activity type,' do
      let(:activity) { create(:activity) }

      it_behaves_like 'does not add any question generator job to the sidekiq queue'
    end
  end
end
