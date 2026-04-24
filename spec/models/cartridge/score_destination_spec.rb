describe Cartridge::ScoreDestination do
  let(:section) { create(:section) }
  let(:user) { create(:user) }
  let(:activity) { create(:activity) }
  let(:lis_result_sourcedid) { SecureRandom.uuid }
  let!(:score_destination) { create(:cartridge_score_destination) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:section) }
  it { is_expected.to belong_to(:activity) }

  it { is_expected.to validate_presence_of(:lis_result_sourcedid) }

  describe '#find_by_user_section_activity' do
    it 'returns the expected instance' do
      retrieved_score_destination =
        Cartridge::ScoreDestination.find_by_user_section_activity(user: score_destination.user,
                                                                  section: score_destination.section,
                                                                  activity: score_destination.activity)
      expect(retrieved_score_destination).to eq score_destination
    end
  end

  describe '#add_or_update' do
    it 'adds a new instance' do
      expect do
        Cartridge::ScoreDestination.add_or_update(user: user,
                                                  section: section,
                                                  activity: activity,
                                                  lis_result_sourcedid: lis_result_sourcedid)
      end.to change(Cartridge::ScoreDestination, :count).by(1)
      expect(Cartridge::ScoreDestination.last).to have_attributes(
        user_id: user.id,
        section_id: section.id,
        activity_id: activity.id,
        lis_result_sourcedid: lis_result_sourcedid)
    end

    it 'finds an existing instance' do
      expect do
        Cartridge::ScoreDestination.add_or_update(user: score_destination.user,
                                                  section: score_destination.section,
                                                  activity: score_destination.activity,
                                                  lis_result_sourcedid: lis_result_sourcedid)
      end.to change(Cartridge::ScoreDestination, :count).by(0)
    end

    it 'finds an existing instance and updates the lis_result_sourcedid' do
      new_lis_result_sourcedid = SecureRandom.uuid
      Cartridge::ScoreDestination.add_or_update(user: score_destination.user,
                                                section: score_destination.section,
                                                activity: score_destination.activity,
                                                lis_result_sourcedid: new_lis_result_sourcedid)
      expect(score_destination.reload.lis_result_sourcedid).to eq(new_lis_result_sourcedid)
    end
  end
end
