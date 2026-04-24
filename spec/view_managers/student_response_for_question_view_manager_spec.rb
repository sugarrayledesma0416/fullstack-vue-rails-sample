describe StudentResponseForQuestionViewManager do
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.lessons.first }
  let(:activity) { create(:activity, lesson:) }
  let(:attempt) { create(:attempt, activity:, user: student) }
  let(:question_label) { 'question 01' }
  let(:question) do
    instance_double(
      MaestroActivityEngine::ActivityContent::OpenEnded::Item,
      question_number: 33,
      label: question_label
    )
  end
  let(:response_id) { 'response id' }
  let(:feedback_item) { build_stubbed(:feedback_item) }
  let(:instructor_comment_recording_path) { 'instructor_comment_recording_path' }
  let(:is_new_recording) { true }
  let(:editor_index) { 1 }
  let(:params) { {} }
  let(:view_manager) { create_view_manager }

  def create_view_manager(opts = {})
    default_opts = {
      activity:,
      attempt: attempt,
      editor_index: editor_index,
      feedback_item: feedback_item,
      instructor:,
      instructor_comment_recording_path: instructor_comment_recording_path,
      is_new_recording: is_new_recording,
      grading_suggestion_data: {
        suggestions: [],
        suggestion_job: nil
      },
      params: params,
      question: question,
      response_id: response_id,
      student: student
    }
    described_class.new(**default_opts.merge(opts))
  end

  it_behaves_like 'an object that expects table activity questions'

  describe '#question_number' do
    it 'returns the question number' do
      expect(view_manager.question_number).to eq(question.question_number)
    end
  end

  describe '#results' do
    it 'returns the results for the question when there is an attempt' do
      results = instance_double(MaestroActivityEngine::ActivityContent::Results)
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      expect(view_manager.results).to eq(results)
    end
  end

  describe '#response' do
    context 'when there is no attempt,' do
      let(:attempt) { nil }

      it 'returns nil' do
        expect(view_manager.response).to be_nil
      end
    end

    context 'when there is an attempt,' do
      let(:results) do
        instance_double(MaestroActivityEngine::ActivityContent::Results)
      end

      before do
        allow(attempt).to receive(:results_for_question)
          .with(question_label).and_return(results)
      end

      context 'when there is no response for the question,' do
        before do
          allow(results).to receive(:has_response?)
            .with(question_label).and_return(false)
        end

        it 'returns nil' do
          expect(view_manager.response).to be_nil
        end
      end

      context 'when there is a response for the question,' do
        let(:response) { 'some response' }

        before do
          allow(results).to receive(:has_response?)
            .with(question_label).and_return(true)
          allow(results).to receive(:response)
            .with(question_label).and_return(response)
        end

        it 'returns the response for the question' do
          expect(view_manager.response).to eq(response)
        end
      end
    end
  end

  describe '#has_valid_response?' do
    let(:results) do
      instance_double(MaestroActivityEngine::ActivityContent::Results)
    end
    let(:response) { 'some response' }

    before do
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(question_label).and_return(true)
    end

    it 'returns true when the student response has text and html tags' do
      allow(results).to receive(:response)
        .with(question_label).and_return('<br><p>a new text</p></br>')
      expect(view_manager).to have_valid_response
    end

    it 'returns false when the student response only has spaces' do
      allow(results).to receive(:response)
        .with(question_label).and_return('&nbsp;&nbsp;&nbsp;&nbsp;')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has html tags' do
      allow(results).to receive(:response)
        .with(question_label).and_return('<br><p></p></br>')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has new empty lines' do
      allow(results).to receive(:response)
        .with(question_label).and_return("\r\n")
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has new empty lines and spaces' do
      allow(results).to receive(:response)
        .with(question_label).and_return("\r\n&nbsp;\r\n")
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has html tags and spaces' do
      allow(results).to receive(:response)
        .with(question_label).and_return('&nbsp;<br><p>&nbsp;</p></br>&nbsp;')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response is empty' do
      allow(results).to receive(:response)
        .with(question_label).and_return('')
      expect(view_manager).not_to have_valid_response
    end
  end

  describe '#inline_corrections' do
    let(:results) do
      instance_double(MaestroActivityEngine::ActivityContent::Results)
    end
    let(:inline_corrections_from_attempt) { nil }

    before do
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(question_label).and_return(true)
      allow(results).to receive(:response)
        .with(question_label).and_return(inline_corrections_from_attempt)
    end

    context 'when the question is not a composition question' do
      it 'returns an empty string' do
        expect(view_manager.inline_corrections).to eq('')
      end
    end

    context 'when the question is a composition question' do
      let(:question) do
        MaestroActivityEngine::ActivityContent::Composition::Item.new
      end

      before do
        allow(question).to receive(:label).and_return(question_label)
      end

      it 'returns nil' do
        expect(view_manager.inline_corrections).to be_nil
      end
    end

    context 'when there is a response for the question from the attempt,' do
      let(:inline_corrections_from_attempt) { 'inline corrections from attempt' }

      it 'returns the inline corrections from the attempt' do
        expect(view_manager.inline_corrections).to eq(inline_corrections_from_attempt)
      end

      context 'when the feedback item has inline corrections,' do
        let(:inline_corrections_from_fb_item) { 'inline corrections from fb item' }

        before do
          allow(feedback_item).to receive(:inline_corrections)
            .and_return(inline_corrections_from_fb_item)
        end

        it 'returns the inline corrections from the feedback item' do
          expect(view_manager.inline_corrections).to eq(inline_corrections_from_fb_item)
        end

        context 'when there are inline corrections in the params,' do
          let(:inline_corrections_from_params) { 'inline corrections from params' }
          let(:params) do
            {
              "inline_corrections_for_#{response_id}" => inline_corrections_from_params
            }
          end

          it 'returns the inline corrections from params' do
            expect(view_manager.inline_corrections).to eq(inline_corrections_from_params)
          end
        end
      end
    end
  end

  describe '#attachment' do
    let(:results) do
      instance_double(MaestroActivityEngine::ActivityContent::Results)
    end
    let(:attachment) { 'some attachment' }

    before do
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      allow(results).to receive(:attachment_for)
        .with(question_label).and_return(attachment)
    end

    it 'returns the attachment for the question' do
      expect(view_manager.attachment).to eq(attachment)
    end
  end

  describe '#has_attachment?' do
    let(:results) do
      instance_double(MaestroActivityEngine::ActivityContent::Results)
    end

    before do
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      allow(results).to receive(:attachment_for)
        .with(question_label).and_return(attachment)
    end

    context 'when the result has no attachment,' do
      let(:attachment) { nil }

      it 'returns false' do
        expect(view_manager).not_to have_attachment
      end
    end

    context 'when the result has an attachment,' do
      let(:attachment) { 'some attachment' }

      it 'returns true' do
        expect(view_manager).to have_attachment
      end
    end
  end

  describe '#inline_corrections_field' do
    it 'returns a name for the student response textarea' do
      expect(view_manager.inline_corrections_field).to eq(
        "inline_corrections_for_#{response_id}"
      )
    end
  end

  describe '#show_student_response_link?' do
    it 'returns false when there is no feedback item' do
      view_manager = create_view_manager(feedback_item: nil)
      expect(view_manager).not_to be_show_student_response_link
    end

    it 'returns false when the feedback item has no inline corrections' do
      allow(feedback_item).to receive(:inline_corrections).and_return(nil)
      expect(view_manager).not_to be_show_student_response_link
    end

    context 'when the feedback item has inline corrections,' do
      before do
        allow(feedback_item).to receive(:inline_corrections)
          .and_return('some corrections')
      end

      it 'returns true' do
        expect(view_manager).to be_show_student_response_link
      end

      it 'returns false when question is a recording question' do
        view_manager = create_view_manager(
          question: MaestroActivityEngine::ActivityContent::Recording::Question.new
        )
        expect(view_manager).not_to be_show_student_response_link
      end
    end
  end

  describe '#composition_question?' do
    it 'returns false' do
      expect(view_manager).not_to be_composition_question
    end

    it 'returns true when the question is a composition question' do
      view_manager = create_view_manager(
        question:  MaestroActivityEngine::ActivityContent::Composition::Item.new
      )
      expect(view_manager).to be_composition_question
    end
  end

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_smartbook_question` doesn't make sense.
  describe '#smartbook_question?' do
    it 'returns false' do
      expect(view_manager.smartbook_question?).to be_falsey
    end

    it 'returns true when the question is a smartbook question' do
      question = Smartbook::Response.new({})
      view_manager = create_view_manager(question: question)
      expect(view_manager.smartbook_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_smartbook_audio_recording_question` doesn't make sense.
  describe '#smartbook_audio_recording_question?' do
    it 'returns false' do
      expect(view_manager.smartbook_audio_recording_question?).to be_falsey
    end

    it 'returns true when the question is a smartbook audio recording question' do
      question = Smartbook::Response.new({})
      allow(question).to receive(:question_type).and_return('voice_recording')
      view_manager = create_view_manager(question: question)
      expect(view_manager.smartbook_audio_recording_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_smartbook_matching_question` doesn't make sense.
  describe '#smartbook_matching_question?' do
    it 'returns false' do
      expect(view_manager.smartbook_matching_question?).to be_falsey
    end

    it 'when the question is a smartbook matching question' do
      question = Smartbook::Response.new({})
      allow(question).to receive(:question_type).and_return('matching')
      view_manager = create_view_manager(question: question)
      expect(view_manager.smartbook_matching_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_smartbook_drawing_question` doesn't make sense.
  describe '#smartbook_drawing_question?' do
    it 'returns false' do
      expect(view_manager.smartbook_drawing_question?).to be_falsey
    end

    it 'when the question is a smartbook drawing question' do
      question = Smartbook::Response.new({})
      allow(question).to receive(:question_type).and_return('drawing')
      view_manager = create_view_manager(question: question)
      expect(view_manager.smartbook_drawing_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_recording_question` doesn't make sense.
  describe '#recording_question?' do
    it 'returns false' do
      expect(view_manager.recording_question?).to be_falsey
    end

    it 'returns true when the question is a recording question' do
      view_manager = create_view_manager(
        question: MaestroActivityEngine::ActivityContent::Recording::Question.new
      )
      expect(view_manager.recording_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  # rubocop:disable RSpec/PredicateMatcher
  # because `be_solo_video_recording_question?` doesn't make sense.
  describe '#solo_video_recording_question?' do
    it 'returns false' do
      expect(view_manager.solo_video_recording_question?).to be_falsey
    end

    it 'returns true when the question is a solo video recording question' do
      view_manager = create_view_manager(
        question: MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item.new
      )
      expect(view_manager.solo_video_recording_question?).to be_truthy
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#score_controls_view_manager' do
    let(:response) { 'some response' }
    let(:results) { instance_double(MaestroActivityEngine::ActivityContent::Results) }

    before do
      allow(attempt).to receive(:results_for_question)
        .with(question_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(question_label).and_return(true)
      allow(results).to receive(:response)
        .with(question_label).and_return(response)
      allow(ScoreControlsViewManager).to receive(:new)
    end

    it 'returns a score control view manager' do
      view_manager.score_controls_view_manager
      expect(ScoreControlsViewManager).to have_received(:new)
        .with(question, feedback_item, results, response_id, params)
    end

    context 'when the question is from a smartbook,' do
      it 'returns a score control view manager' do
        view_manager.score_controls_view_manager
        expect(ScoreControlsViewManager).to have_received(:new)
          .with(question, feedback_item, results, response_id, params)
      end
    end
  end

  describe '#mount_ai_grading_app?' do
    it 'returns false for activities that do no support AI grading' do
      expect(view_manager.mount_ai_grading_app?).to be(false)
    end

    context 'when the activity supports AI grading,' do
      before do
        activity.update!(activity_type: 'composition')
      end

      it 'returns false' do
        expect(view_manager.mount_ai_grading_app?).to be(false)
      end

      it 'returns true when the program has the AI grading feature enabled' do
        create(
          :program_config,
          program:,
          ai_settings: { grading_suggestions: true }
        )

        expect(view_manager.mount_ai_grading_app?).to be(true)
      end

      it 'returns true when the instructor has the AI grading enabled for his account' do
        instructor.grant_access_to_ai_grading_suggestions

        expect(view_manager.mount_ai_grading_app?).to be(true)
      end

      it 'returns true if there if grading suggestions exist for that attempt' do
        create(
          :ai_grading_suggestion,
          activity:,
          attempt:,
          question_label: question.label
        )

        expect(view_manager.mount_ai_grading_app?).to be(true)
      end

      it 'returns true if there if an overall comment exists for that attempt' do
        create(
          :ai_overall_comment,
          activity:,
          attempt:,
          question_label: question.label
        )

        expect(view_manager.mount_ai_grading_app?).to be(true)
      end
    end
  end

  describe '#ai_grading_feature_enabled?' do
  end

  describe '#student_section_config' do
    let(:section) { attempt.section }
    let(:student) { create(:student) }
    let(:attempt) { create(:attempt, activity: activity, user: student) }
    let(:view_manager) { create_view_manager(attempt: attempt, student: student) }

    context 'when a StudentSectionConfig exists for the student and section' do
      let!(:student_section_config) { create(:student_section_config, section: section, user: student, input_mode: 'text') }

      it 'returns the StudentSectionConfig object' do
        expect(view_manager.student_section_config).to eq(student_section_config)
      end
    end

    context 'when no StudentSectionConfig exists for the student and section' do
      it 'returns an empty hash' do
        expect(view_manager.student_section_config).to eq({})
      end
    end
  end
end
