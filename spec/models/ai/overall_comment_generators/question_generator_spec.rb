describe AI::OverallCommentGenerators::QuestionGenerator do
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.lessons.first }
  let(:activity) { create(:activity, activity_type: 'open_ended', lesson:) }
  let(:attempt) { create(:attempt_submitted, activity:) }
  let(:prompt) { create(:ai_overall_comment_prompt, model: 'gpt-4o-2024-08-06') } # We have to use a specific model that support json_schema
  let(:direction_line) { 'this is the direction line' }
  let(:audio_transcript) { 'this is the audio transcript' }
  let(:image_alt_tag) {}
  let(:model_text) {}
  let(:question_prompt) { 'this is the question prompt'}
  let(:video_transcript) { 'this is the video transcript' }
  let(:vhl_client) { instance_double(VHL::AI::Core::Client) }
  let(:abtest_adapter) { instance_double(AI::AbtestAdapter) }
  let(:wordbank_words) {}
  let(:reference_data) do
    {
      audio_transcript:,
      image_alt_tag:,
      model_text:,
      video_transcript:,
      wordbank_words:
    }
  end
  let(:sample_answers) { "Sample answer 1\nSample answer 2" }
  let(:activity_extractor) do
    instance_double(
      AI::ActivityExtractor,
      direction_line:,
      reference_data:
    )
  end
  let(:references_formatter) { instance_double(AI::ActivityReferencesFormatter) }
  let(:question_label) { 'question_01' }
  let(:student_submission) { 'blah' }
  let(:grading_suggestion_input) do
    create(
      :ai_grading_suggestion_input,
      program:,
      attempt:,
      activity:,
      question_label:
    )
  end
  let(:generator) do
    described_class.new(
      attempt:,
      grading_suggestion_input:,
      prompt:,
      question_label:,
      student_submission:
    )
  end

  describe '#generate' do
    let(:evaluation_text) do
      {
        overall_comment: 'Nice',
        explanation: 'You did it.'
      }
    end
    let(:ai_response) do
      VHL::AI::Schemas::OpenAI::Response::OverallCommentSchema.new(
        overall_comment: evaluation_text[:overall_comment],
        explanation: evaluation_text[:explanation],
        role: 'assistant'
      )
    end
    let(:formatted_references) { '<references><audio_transcript>this is the audio transcript</audio_transcript><video_transcript>this is the video transcript</video_transcript></references>' }

    before do
      allow(AI::ActivityExtractor).to receive(:new).with(activity).and_return(activity_extractor)
      allow(activity_extractor).to receive(:question_sample_answers).with('question_01').and_return(
        sample_answers.split("\n")
      )
      allow(activity_extractor).to receive(:question_prompt).with('question_01').and_return(
        question_prompt
      )

      allow(AI::AbtestAdapter).to receive(:new).and_return(abtest_adapter)
      allow(AI::ActivityReferencesFormatter).to receive(:new).with(activity).and_return(references_formatter)
      allow(references_formatter).to receive(:format_as_xml).and_return(formatted_references)
      allow(abtest_adapter).to receive(:generate_overall_comment).and_return(ai_response)

      # Mock AI Core prompts to return expected test values
      allow(VHL::AI::Prompts).to receive(:has_prompt?).with('overall_comment', program.language_code).and_return(false)
    end

    it 'makes a request to the AI service' do
      generator.generate

      system_message = {
        role: 'system',
        content: prompt.template_body  # Raw template, not expanded
      }
      prompt_message = format(
        described_class::USER_PROMPT_TEMPLATE,
        student_answer: student_submission,
        direction_line:,
        question_prompt:
      )
      sample_answers_message = format(
        described_class::SAMPLE_ANSWERS_TEMPLATE,
        sample_answers:
      )

      user_message = {
        role: 'user',
        content: "#{prompt_message}#{sample_answers_message}#{formatted_references}"
      }
      expect(abtest_adapter).to have_received(:generate_overall_comment).with(
        prompt: prompt,
        messages: [system_message, user_message],
        experiment_name: nil,
        template_variables: {
          program_level: 'introductory',
          language_name: 'Spanish'
        },
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => attempt&.user&.id,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => attempt&.id,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt&.id
        }
      )
    end

    it 'creates an overall comment record' do
      expect do
        generator.generate
      end.to change(AI::OverallComment, :count).by(1)

      expect(AI::OverallComment.last).to have_attributes(
        activity:,
        prompt_id: prompt.id,
        attempt:,
        evaluation_text:,
        grading_suggestion_input:,
        language_code: program.language_code,
        program:,
        question_label:
      )
    end

    context 'when the AI client raises an error' do
      before do
        allow(abtest_adapter).to receive(:generate_overall_comment).and_raise(StandardError, 'boom')
        allow(STATS_PROXY).to receive(:error)
      end

      it 'does not raise and does not create a comment' do
        expect { generator.generate }.not_to raise_error
        expect(AI::OverallComment.count).to eq(0)
      end
    end

    context 'when the AI client returns nil' do
      before do
        allow(abtest_adapter).to receive(:generate_overall_comment).and_return(nil)
      end

      it 'does not create an overall comment' do
        expect { generator.generate }.not_to change(AI::OverallComment, :count)
      end
    end

    context 'when the AI client raises a SchemaError' do
      before do
        allow(abtest_adapter).to receive(:generate_overall_comment).and_raise(VHL::AI::Core::SchemaError, 'schema mismatch')
      end

      it 'logs the schema error and does not create a comment' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect { generator.generate }.not_to raise_error
        expect(AI::OverallComment.count).to eq(0)
      end
    end

    it 'passes the correct span attributes to the AI client' do
      allow(abtest_adapter).to receive(:generate_overall_comment).and_return(ai_response)

      generator.generate

      system_message = {
        role: 'system',
        content: prompt.template_body  # Raw template, not expanded
      }
      prompt_message = format(
        described_class::USER_PROMPT_TEMPLATE,
        student_answer: student_submission,
        direction_line:,
        question_prompt:
      )
      sample_answers_message = format(
        described_class::SAMPLE_ANSWERS_TEMPLATE,
        sample_answers:
      )

      user_message = {
        role: 'user',
        content: "#{prompt_message}#{sample_answers_message}#{formatted_references}"
      }

      expect(abtest_adapter).to have_received(:generate_overall_comment).with(
        prompt: prompt,
        messages: [system_message, user_message],
        experiment_name: nil,
        template_variables: {
          program_level: 'introductory',
          language_name: 'Spanish'
        },
        span_attributes: {
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_USER_ID => attempt&.user&.id,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_SESSION_ID => attempt&.id,
          VHL::AI::Tracing::SpanAttributes::LANGFUSE_PROMPT_VERSION => prompt&.id
        }
      )
    end
  end
end
