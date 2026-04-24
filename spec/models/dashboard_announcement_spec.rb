describe DashboardAnnouncement do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_presence_of(:external_url) }
    it { is_expected.to validate_presence_of(:link_text) }
  end

  describe 'remove_previous_announcement changes visible announcement to false' do
    before(:each) do
      create(:dashboard_announcement, title: 'Title', body: 'Body', vol: true, supersite: true)
    end
    it 'changes vol to false' do
      DashboardAnnouncement.remove_previous_announcement(:vol)
      vol_false = DashboardAnnouncement.where(vol: true).last
      expect(vol_false).to be_nil
    end
    it 'changes supersite to false' do
      DashboardAnnouncement.remove_previous_announcement(:supersite)
      ss_false = DashboardAnnouncement.where(supersite: true).last
      expect(ss_false).to be_nil
    end
  end
end
