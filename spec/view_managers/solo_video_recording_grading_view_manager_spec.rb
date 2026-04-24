describe SoloVideoRecordingGradingViewManager do
  let(:student) { build_stubbed(:student) }
  let(:question) { double('Question') }
  let(:presenter) { double('PartnerChatPresenter') }
  let(:view_manager) { SoloVideoRecordingGradingViewManager.new(presenter, student, question) }


  describe "#studentfeedback" do
    it "returns the grading feedback for the student" do
      student_feedback = double('GradingFeedback')
      response_id = 'fake_response_id'
      feedback = { response_id => student_feedback }
      allow(view_manager).to receive(:student).and_return(student)
      expect(presenter).to receive(:feedback).and_return(feedback)
      expect(presenter).to receive(:response_id).with(student, question).and_return(response_id)
      expect(view_manager.student_feedback).to eql student_feedback
    end
  end

  describe "#student_recording_path" do
    it "returns the student's solo video recording path" do
      recording_path = 'fake/recording/path.mp4'
      allow(view_manager).to receive(:student).and_return(student)
      expect(presenter).to receive(:recording_path).with(student, question).and_return(recording_path)
      expect(view_manager.student_recording_path).to eql recording_path
    end
  end

  describe "#video_id" do
    it "returns an id string to uniquely identify a video jsplayer container on the grading page" do
      allow(view_manager).to receive(:student).and_return(student)
      expect(view_manager.video_id).to eql "solo_video_recording_container_#{student.id}"
    end
  end
end
