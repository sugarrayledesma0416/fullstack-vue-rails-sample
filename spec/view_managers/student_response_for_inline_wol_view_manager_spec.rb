describe StudentResponseForInlineWolViewManager do
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor) }
  let(:activity) { create(:activity) }
  let(:attempt) { create(:attempt, activity:, user: student) }
  let(:wol_label) { 'question 01_wol_1' }
  let(:wol) do
    instance_double(
      MaestroActivityEngine::ActivityContent::Question::InlineOpenEndedContent::WriteOnLine,
      question_number: 33,
      label: wol_label
    )
  end
  let(:response_id) { "question 01_wol_1_student_#{student.id}" }
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
      question: wol,
      response_id:,
      student:
    }
    described_class.new(**default_opts.merge(opts))
  end

  describe '#question_number' do
    it 'returns the question number' do
      expect(view_manager.question_number).to eq(wol.question_number)
    end
  end

  describe '#results' do
    it 'returns the results for the question when there is an attempt' do
      results = instance_double(MaestroActivityEngine::ActivityContent::Results)
      allow(attempt).to receive(:results_for_question)
        .with(wol_label).and_return(results)
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
          .with(wol_label).and_return(results)
      end

      context 'when there is no response for the question,' do
        before do
          allow(results).to receive(:has_response?)
            .with(wol_label).and_return(false)
        end

        it 'returns nil' do
          expect(view_manager.response).to be_nil
        end
      end

      context 'when there is a response for the question,' do
        let(:response) { 'some response' }

        before do
          allow(results).to receive(:has_response?)
            .with(wol_label).and_return(true)
          allow(results).to receive(:response)
            .with(wol_label).and_return(response)
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
        .with(wol_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(wol_label).and_return(true)
    end

    it 'returns true when the student response has text and html tags' do
      allow(results).to receive(:response)
        .with(wol_label).and_return('<br><p>a new text</p></br>')
      expect(view_manager).to have_valid_response
    end

    it 'returns false when the student response only has spaces' do
      allow(results).to receive(:response)
        .with(wol_label).and_return('&nbsp;&nbsp;&nbsp;&nbsp;')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has html tags' do
      allow(results).to receive(:response)
        .with(wol_label).and_return('<br><p></p></br>')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has new empty lines' do
      allow(results).to receive(:response)
        .with(wol_label).and_return("\r\n")
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has new empty lines and spaces' do
      allow(results).to receive(:response)
        .with(wol_label).and_return("\r\n&nbsp;\r\n")
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response only has html tags and spaces' do
      allow(results).to receive(:response)
        .with(wol_label).and_return('&nbsp;<br><p>&nbsp;</p></br>&nbsp;')
      expect(view_manager).not_to have_valid_response
    end

    it 'returns false when the student response is empty' do
      allow(results).to receive(:response)
        .with(wol_label).and_return('')
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
        .with(wol_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(wol_label).and_return(true)
      allow(results).to receive(:response)
        .with(wol_label).and_return(inline_corrections_from_attempt)
    end

    context 'when the question is not a composition question' do
      it 'returns an empty string' do
        expect(view_manager.inline_corrections).to eq('')
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
        .with(wol_label).and_return(results)
      allow(results).to receive(:attachment_for)
        .with(wol_label).and_return(attachment)
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
        .with(wol_label).and_return(results)
      allow(results).to receive(:attachment_for)
        .with(wol_label).and_return(attachment)
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

  describe '#score_controls_view_manager' do
    let(:response) { 'some response' }
    let(:results) { instance_double(MaestroActivityEngine::ActivityContent::Results) }

    before do
      allow(attempt).to receive(:results_for_question)
        .with(wol_label).and_return(results)
      allow(results).to receive(:has_response?)
        .with(wol_label).and_return(true)
      allow(results).to receive(:response)
        .with(wol_label).and_return(response)
      allow(ScoreControlsViewManager).to receive(:new)
    end

    it 'returns a score control view manager' do
      view_manager.score_controls_view_manager
      expect(ScoreControlsViewManager).to have_received(:new)
        .with(wol, feedback_item, results, response_id, params)
    end

    context 'when the question is from a smartbook,' do
      it 'returns a score control view manager' do
        view_manager.score_controls_view_manager
        expect(ScoreControlsViewManager).to have_received(:new)
          .with(wol, feedback_item, results, response_id, params)
      end
    end
  end
end
