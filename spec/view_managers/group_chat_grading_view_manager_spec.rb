describe GroupChatGradingViewManager do
  let(:student) { build_stubbed(:student) }
  let(:partner_students) { build_stubbed_list(:student, 3) }
  let(:all_students) { [student] + partner_students }
  let(:question) do
    instance_double(MaestroActivityEngine::ActivityContent::Common::QuestionLabel)
  end
  let(:presenter) do
    instance_double(ReviewWorkPresenter, teammates: partner_students, feedback: feedback)
  end
  let(:recording_paths) do
    all_students.each_with_object({}) do |user, hash|
      hash[user.id] = "recording_path_for_user_#{user.id}"
    end
  end
  let(:feedback) do
    all_students.each_with_object({}) do |user, hash|
      hash["feedback_id_#{user.id}"] = "instructor_feedback_for_user_#{user.id}"
    end
  end
  let(:view_manager) { described_class.new(presenter, student, question) }

  before do
    all_students.each do |user|
      allow(presenter).to receive(:recording_path).with(user, question)
                                                  .and_return(recording_paths[user.id])
      allow(presenter).to receive(:response_id).with(user, question)
                                               .and_return("feedback_id_#{user.id}")
    end
  end

  describe '#feedback_for' do
    it 'returns the instructor feedback for the student being graded' do
      expect(view_manager.feedback_for(student)).to eq feedback["feedback_id_#{student.id}"]
    end

    it 'returns the instructor feedback for the partner students' do
      expect(view_manager.feedback_for(partner_students[0])).to eq feedback["feedback_id_#{partner_students[0].id}"]
      expect(view_manager.feedback_for(partner_students[1])).to eq feedback["feedback_id_#{partner_students[1].id}"]
      expect(view_manager.feedback_for(partner_students[2])).to eq feedback["feedback_id_#{partner_students[2].id}"]
    end
  end

  describe '#recording_path_for' do
    it 'returns the recording path for the student being graded' do
      expect(view_manager.recording_path_for(student)).to eq recording_paths[student.id]
    end

    it 'returns the recording path for the partner students' do
      expect(view_manager.recording_path_for(partner_students[0])).to eq recording_paths[partner_students[0].id]
      expect(view_manager.recording_path_for(partner_students[1])).to eq recording_paths[partner_students[1].id]
      expect(view_manager.recording_path_for(partner_students[2])).to eq recording_paths[partner_students[2].id]
    end
  end

  describe '#video_container_id' do
    it 'returns a string that will indentify the video html container' do
      expected_string = "group_chat_container_#{student.id}" \
        "_#{partner_students.map(&:id).join('_')}"
      expect(view_manager.video_container_id).to eq expected_string
    end
  end
end
