describe GroupChatPresenter do
  let(:user) { build_stubbed(:student) }
  let(:partner_students) { build_stubbed_list(:student, 3) }
  let(:participant_ids) { partner_students.map { |partner| partner.id.to_s } }
  let(:group_chat_recording) do
    user_association = instance_double(ActiveRecord::Associations::Association)
    allow(user_association).to receive(:target=)

    instance_double(GroupChatRecording,
                    participants: participant_ids,
                    practicing_users: [],
                    partner_users: partner_students.index_by(&:id),
                    user: user).tap do |recording|
      allow(recording).to receive(:association).with(:user).and_return(user_association)
      allow(recording).to receive(:user_id).and_return(user.id)
    end
  end
  let(:presenter) { described_class.new([group_chat_recording]) }

  describe '#original_user' do
    it 'returns the user that did the submission if the given user is a partner user' do
      partner_students.each do |partner|
        expect(presenter.original_user(partner)).to eq user
      end
    end

    it 'returns the user that did the submission if the given user is the one' \
       'that did the submission' do
      expect(presenter.original_user(user)).to eq user
    end

    it 'raises an exception if the given user was not in the group chat call' do
      expect do
        presenter.original_user(build_stubbed(:student))
      end.to raise_error NoMethodError
    end
  end

  describe '#original_partner' do
    it 'returns the user referenced by the GroupChatRecording partner_id field' do
      presenter = described_class.new([group_chat_recording])
      partner_students.each do |partner|
        expect(presenter.original_partner(partner)).to eq partner
      end
    end

    it 'returns nil if the passed user is the user that did the submission' do
      expect(presenter.original_partner(user)).to be_nil
    end

    it 'raises an exception if the given user was no in the group chat call' do
      expect do
        presenter.original_partner(build_stubbed(:student))
      end.to raise_error NoMethodError
    end
  end

  describe '#sort_students' do
    it 'sorts students by placing the student that did the submission first and all partners after' do
      expect(presenter.sort_students(partner_students + [user])).to match_array([user] + partner_students)
    end
  end
end
