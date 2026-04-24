describe GroupChatRecording, core: true do
  let(:group_chat_recording) { create(:group_chat_recording) }

  describe '#partner_users' do
    it 'returns a hash with the list of the students that participated in the group chat' do
      student_1 = create(:student)
      student_2 = create(:student)
      student_3 = create(:student)
      group_chat_recording.participants = [student_1.id, student_2.id, student_3.id]
      expect(group_chat_recording.partner_users). to eq(
        student_1.id => student_1,
        student_2.id => student_2,
        student_3.id => student_3
      )
    end

    it 'returns an empty hash if there are no participants' do
      group_chat_recording.participants = []
      expect(group_chat_recording.partner_users).to eq({})
    end
  end
end
