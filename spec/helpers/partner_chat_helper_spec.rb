describe PartnerChatHelper do
  include ApplicationHelper
  include PartnerChatHelper

  describe '#partner_chat_recording_url' do
    it 'returns the recording path for a response based upon the cdn configuration' do
      response = double('Response')
      allow(response).to receive(:[]).with(:recording_path).and_return('foo.mp4')
      allow(response).to receive(:[]).with(:token).and_return('bar')
      url = "https://partner-chat.example.com/foo.mp4"

      expect(helper.partner_chat_recording_url(response)).to eq(url)
    end

    it 'returns an empty string if there is no recording_path' do
      response = double('Response')
      allow(response).to receive(:[]).with(:recording_path).and_return('')

      expect(helper.partner_chat_recording_url(response)).to eq('')
    end
  end

  describe '#partner_chat_class' do
    let(:student) { build_stubbed(:student) }

    context 'when the student is the student to be graded' do
      it 'returns current_student' do
        expect(helper.partner_chat_class(student, student)).to eq('current_student')
      end
    end

    context 'when the student is not the student to be graded' do
      it 'returns current_partner' do
        other_student = build_stubbed(:student)
        expect(helper.partner_chat_class(student, other_student)).to eq('current_partner')
      end
    end
  end

  describe '#avatar_meta_tag' do
    it 'returns meta tag html with the user avatar path in it' do
      user = build_stubbed(:user)
      allow(helper).to receive(:current_user).and_return(user)
      expected = "<meta name=\"VHL.avatar_path\" content=\"https://avatars.vhlcentral.com/avatars/#{user.guid}.jpg\"/>"
      expect(helper.avatar_meta_tag).to eql expected
    end
  end
end
