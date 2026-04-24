describe GradingSetQuestionViewLogic do
  class ViewLogicClass
  end

  let(:presenter){ double('Presenter').as_null_object }
  let(:question){ double('Question').as_null_object }
  let(:view_logic){ ViewLogicClass.new.extend(GradingSetQuestionViewLogic) }
  let(:fake_object){ double('FakeObject', :fake_method => nil) } #used to test yield blocks

  before do
    allow(view_logic).to receive(:question).and_return(question)
    allow(view_logic).to receive(:presenter).and_return(presenter)
  end

  describe "#chat_activity?" do
    it "returns true if the activity is a partner chat activity" do
      expect(presenter).to receive(:activity_partner_chat?).and_return(true)
      expect(view_logic.chat_activity?).to be_truthy
    end

    it "returns true if the activity is a virtual chat activity" do
      allow(presenter).to receive(:activity_partner_chat?).and_return(false)
      expect(presenter).to receive(:activity_virtual_chat?).and_return(true)
      expect(view_logic.chat_activity?).to be_truthy
    end
  end

  describe "#question_label" do
    it "returns the label of the question" do
      expect(question).to receive(:label)
      view_logic.question_label
    end
  end

  describe "#audio_file_location" do
    it "returns the filename of the audio prompt for the question" do
      allow(question).to receive_message_chain(:prompt, :audio, :media_item, :public_filename_for_arc).and_return('public_filename')
      expect(view_logic.audio_file_location).to eql 'public_filename'
    end
  end

  describe "#has_prompt?" do
    it "returns true if a question has a prompt" do
      expect(question).to receive(:prompt).and_return(double('Prompt'))
      expect(view_logic.has_prompt?).to be_truthy
    end
  end

  describe "#text_prompt_content" do
    it "yields the given block when the activity is not an arc activity" do
      allow(view_logic).to receive(:arc_activity?).and_return(false)
      expect(fake_object).to receive(:fake_method)
      view_logic.text_prompt_content { fake_object.fake_method }
    end
  end

  describe "when the activity is not an arc activity" do
    it "yields the sample answer template name" do
      allow(view_logic).to receive(:arc_activity?).and_return(false)
      expect(view_logic.sample_answer_content { |template| template }).to eql '/instructor/grading_sets/sample_answer'
    end
  end

  describe "#solo_video_recording_activity?" do
    it "returns true if the activity is a solo_video_recording activity" do
      expect(presenter).to receive(:activity_solo_video_recording?).and_return(true)
      expect(view_logic.solo_video_recording_activity?).to be_truthy
    end
  end

end
