describe PartnerChatGradingViewManager do
  let(:student) { build_stubbed(:student) }
  let(:question) { double('Question') }
  let(:presenter) { double('PartnerChatPresenter') }
  let(:view_manager) { PartnerChatGradingViewManager.new(presenter, student, question) }
  let(:student_on_left) { student }
  let(:student_on_right) { build_stubbed(:student) }

  describe "#student_on_left" do
    it "returns the student to be displayed on the left of the grading view" do
      expect(presenter).to receive(:original_user).with(student).and_return(student_on_left)
      expect(view_manager.student_on_left).to eql student_on_left
    end
  end

  describe "#student_on_right" do
    it "returns the student to be displayed on the right of the grading view" do
      expect(presenter).to receive(:original_partner).with(student).and_return(student_on_right)
      expect(view_manager.student_on_right).to eql student_on_right
    end
  end

  describe "#student_on_left_feedback" do
    it "returns the feedback for the student on the left" do
      student_on_left_feedback = double('GradingFeedback')
      response_id = 'fake_response_id'
      feedback = { response_id => student_on_left_feedback }
      allow(view_manager).to receive(:student_on_left).and_return(student_on_left)
      expect(presenter).to receive(:feedback).and_return(feedback)
      expect(presenter).to receive(:response_id).with(student_on_left, question).and_return(response_id)
      expect(view_manager.student_on_left_feedback).to eql student_on_left_feedback
    end
  end

  describe "#student_on_right_feedback" do
    it "returns the feedback for the student on the right" do
      student_on_right_feedback = double('GradingFeedback')
      response_id = 'fake_response_id'
      feedback = { response_id => student_on_right_feedback }
      allow(view_manager).to receive(:student_on_right).and_return(student_on_right)
      expect(presenter).to receive(:feedback).and_return(feedback)
      expect(presenter).to receive(:response_id).with(student_on_right, question).and_return(response_id)
      expect(view_manager.student_on_right_feedback).to eql student_on_right_feedback
    end
  end

  describe "#student_on_left_recording_path" do
    it "returns the recording path for the student on the left" do
      recording_path = 'fake/recording/path.mp4'
      allow(view_manager).to receive(:student_on_left).and_return(student_on_left)
      expect(presenter).to receive(:recording_path).with(student_on_left, question).and_return(recording_path)
      expect(view_manager.student_on_left_recording_path).to eql recording_path
    end
  end

  describe "#student_on_right_recording_path" do
    it "returns the recording path for the student on the right" do
      recording_path = 'fake/recording/path.mp4'
      allow(view_manager).to receive(:student_on_right).and_return(student_on_right)
      expect(presenter).to receive(:recording_path).with(student_on_right, question).and_return(recording_path)
      expect(view_manager.student_on_right_recording_path).to eql recording_path
    end
  end

  describe "#video_id" do
    it "returns an id string to uniquely identify a jwplayer container on the grading page" do
      allow(view_manager).to receive(:student_on_left).and_return(student_on_left)
      allow(view_manager).to receive(:student_on_right).and_return(student_on_right)
      expect(view_manager.video_id).to eql "partner_chat_container_#{student_on_left.id}_#{student_on_right.id}"
    end
  end
end
