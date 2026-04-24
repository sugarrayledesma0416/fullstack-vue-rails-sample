describe MultiTypeActivityViewManager, core: true do
  let(:presenter){ double('Presenter').as_null_object }
  let(:view_manager){ MultiTypeActivityViewManager.new(presenter) }

  before do
    allow(presenter).to receive(:current_student).and_return('student')
  end

  it_behaves_like 'an object that expects table activity questions'

  describe "#current_response_id" do
    it "returns the response id for the current student and given question" do
      expect(presenter).to receive(:response_id).with('student', 'question')
      view_manager.current_response_id('question')
    end
  end

  describe "#feedback_item" do
    it "returns the feedback item for the current student and a given question" do
      allow(view_manager).to receive(:current_response_id).and_return('current_response_id')
      allow(presenter).to receive(:feedback).and_return({'current_response_id' => 'feedback'})
      expect(view_manager.feedback_item('question')).to eql 'feedback'
    end
  end

  describe "recording_path" do
    it "returns the recording path for the current student and the given question" do
      expect(presenter).to receive(:recording_path).with('student', 'question')
      view_manager.recording_path('question')
    end
  end

  describe "#new_recording?" do
    it "returns whether the current student has a new recording for the given question" do
      expect(presenter).to receive(:new_recording?).with('student', 'question')
      view_manager.new_recording?('question')
    end
  end
end
