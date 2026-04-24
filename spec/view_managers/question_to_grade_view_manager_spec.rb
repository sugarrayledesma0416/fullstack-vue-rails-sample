describe QuestionToGradeViewManager do
  let(:presenter) { double('Presenter').as_null_object }
  let(:question) { double('Question').as_null_object }
  let(:view_manager) { QuestionToGradeViewManager.new(presenter, question) }
  let(:activity) { double('Activity', sub_activities: []).as_null_object }
  let(:sub_activity) { double('SubActivity', items: [question]) }
  let(:other_question) { double('Question').as_null_object }
  let(:other_sub_activity) { double('SubActivity', items: [other_question]) }

  it_behaves_like 'an object that expects table activity questions'

  describe "#current_response_id" do
    it "returns the response id for the current student and question" do
      expect(presenter).to receive(:response_id).and_return('response_id')
      expect(view_manager.current_response_id).to eql 'response_id'
    end
  end

  describe "#feedback_has_inline_corrections?" do
    it "returns the inline corrections for the current student and question" do
      allow(view_manager).to receive(:current_response_id).and_return('response_id')
      expect(presenter).to receive(:feedback).twice.and_return({ 'response_id' => double('Feedback', :inline_corrections => 'corrections') })
      expect(view_manager.feedback_has_inline_corrections?).to eql 'corrections'
    end
  end

  describe "#html_friendly_prompt" do
    before do
      def question.html_friendly_prompt
        block_given? ? yield : ''
      end

      def fake_method(*args)
      end
    end

    it "yields the reference formatter method name, and args for it" do
      reference = double(MaestroActivityEngine::ActivityContent::Reference::Base)
      allow(presenter).to receive_message_chain(:activity, :content_object, :items, :detect).and_return(reference)
      expect(self).to receive(:fake_method).with(:format_reference, reference)
      view_manager.html_friendly_prompt{|formatter, *args| fake_method(formatter, *args) }
    end
  end

  describe '#current_question_is_virtual_chat_type?' do
    it 'returns true when question is a virtual chat one' do
      question = MaestroActivityEngine::ActivityContent::VirtualChat::Item.new
      manager = described_class.new(presenter, question)
      expect(manager.current_question_is_virtual_chat_type?).to be_truthy
    end

    it 'returns false when question is not a virtual chat one' do
      manager = described_class.new(presenter, question)
      expect(manager.current_question_is_virtual_chat_type?).to be_falsey
    end
  end

  describe "#show_question_prompt?" do
    it 'returns false when the activity is an ai_virtual_chat' do
      allow(presenter).to receive(:activity_ai_virtual_chat?).and_return(true)

      expect(view_manager.show_question_prompt?).to be_falsey
    end

    context "when the question is a question in a virtual chat or partner chat activity" do
      it "does not show the question prompt" do
        allow(view_manager).to receive(:chat_activity?).and_return(true)
        expect(view_manager.show_question_prompt?).to be_falsey
      end
    end
  end

  describe "#feedback_attachment" do
    before do
      allow(view_manager).to receive(:current_response_id).and_return('response_id')
    end

    it "returns the feedback's attachmentwhen present" do
      expected_attachment = double('attachment')
      allow(presenter).to receive(:feedback).and_return({ 'response_id' => double('Feedback', :composition_attachment => expected_attachment) })
      expect(view_manager.feedback_attachment).to eql expected_attachment
    end

    it "is blank when there's no feedback for the current question" do
      allow(presenter).to receive(:feedback).and_return({})
      expect(view_manager.feedback_attachment).to be_nil
    end
  end

  describe "#has_student_attachment?" do
    it "returns the result of asking the presenter if there is an attachment for the current question" do
      expect(presenter).to receive(:has_student_attachment_for?).with(question).and_return(true)
      expect(view_manager).to have_student_attachment
    end
  end

  describe '#current_question_is_solo_video_recording_question?' do
    it 'returns true when question is a solo video recording one' do
      question = MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item.new
      manager = described_class.new(presenter, question)
      expect(manager.is_solo_video_recording_question?).to be_truthy
    end

    it 'returns false when question is not a solo video recording one' do
      manager = described_class.new(presenter, question)
      expect(manager.is_solo_video_recording_question?).to be_falsey
    end
  end

  describe '#question_content_object' do
    let(:main_activity_content) do
      instance_double(
        MaestroActivityEngine::ActivityContent::Content
      )
    end

    before do
      allow(presenter).to receive(:activity).and_return(activity)
      allow(activity).to receive(:content_object).and_return(
        main_activity_content
      )
    end

    context 'when the main activity has no subactivities' do
      before do
        allow(activity).to receive(:has_sub_activities?).and_return(false)
      end

      it 'returns the content object of the main activity' do
        expect(view_manager.question_content_object).to eq(main_activity_content)
      end
    end

    context 'when the main activity has sub_activities' do
      before do
        allow(activity).to receive(:has_sub_activities?).and_return(true)

        allow(activity).to receive(:sub_activities).and_return(
          [other_sub_activity, sub_activity]
        )
      end

      it 'returns the sub_activity containing the current question' do
        expect(view_manager.question_content_object).to eq(sub_activity)
      end
    end
  end

  describe '#current_sub_activity' do
    before do
      allow(presenter).to receive(:activity).and_return(activity)
    end

    it 'returns the sub activity if question is part of a sub activity' do
      allow(view_manager).to receive(:sub_activity_and_rank_for_current_question)
        .and_return({ rank: 1, sub_activity: sub_activity })
      expect(view_manager.current_sub_activity).to eq(sub_activity)
    end
  end

  describe '#sub_activity_and_rank_for_current_question' do
    before do
      allow(presenter).to receive(:activity).and_return(activity)
    end

    it 'returns the rank and sub activity when question belongs to a sub activity' do
      allow(activity).to receive(:sub_activities).and_return(
        [other_sub_activity, sub_activity]
      )
      result = view_manager.sub_activity_and_rank_for_current_question
      expect(result).to eq({ rank: 2, sub_activity: sub_activity })
    end

    it 'returns nil if no sub activity contains the question' do
      allow(activity).to receive(:sub_activities).and_return([other_sub_activity])
      expect(view_manager.sub_activity_and_rank_for_current_question).to be_nil
    end
  end
end
