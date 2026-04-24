describe CommonGradingViewLogic do
  class ClassThatUsesCommonGrading
  end
  let(:common_logic) { ClassThatUsesCommonGrading.new.extend(CommonGradingViewLogic) }
  let(:presenter) { double('presenter') }

  before do
    allow(common_logic).to receive(:presenter).and_return(presenter)
  end

  describe '#arc_activity?' do
    it 'returns true if the presenters activity is a recording v2 activity' do
      expect(presenter).to receive(:activity_recording_v2?).and_return(true)
      expect(common_logic.arc_activity?).to be_truthy
    end
  end

  describe '#is_virtual_chat_type?' do
    it 'returns true if the activity type is virtual chat' do
      allow(presenter).to receive(:activity_virtual_chat?).and_return(true)
      allow(presenter).to receive(:activity_video_virtual_chat?).and_return(false)
      expect(common_logic.is_virtual_chat_type?).to be_truthy
    end

    it 'returns true if the activity type is video virtual chat' do
      allow(presenter).to receive(:activity_virtual_chat?).and_return(false)
      allow(presenter).to receive(:activity_video_virtual_chat?).and_return(true)

      expect(common_logic.is_virtual_chat_type?).to be_truthy
    end
  end

  describe '#virtual_chat_partial' do
    it 'returns the correct partial folder if the activity type is video virtual chat' do
      allow(presenter).to receive(:activity_video_virtual_chat?).and_return(true)

      expect(common_logic.virtual_chat_partial).to eq('video_virtual_chat')
    end

    it 'returns the correct partial folder if the activity type is not video virtual chat' do
      allow(presenter).to receive(:activity_video_virtual_chat?).and_return(false)

      expect(common_logic.virtual_chat_partial).to eq('virtual_chat')
    end
  end
end
