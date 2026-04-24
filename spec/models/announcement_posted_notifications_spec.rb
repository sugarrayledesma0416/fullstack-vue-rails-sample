describe AnnouncementPostedNotification do
  let(:section) { create(:section_with_course) }
  let(:student) { create(:student) }
  let(:announcement) { create(:announcement) }

  let(:params) do
    { announcement: announcement, section: section, user: student }
  end

  describe '#message' do
    it 'returns an empty string' do
      notification = described_class.create!(params)
      expect(notification.message).to eq('')
    end
  end

  describe '#label' do
    it 'returns the title of the announcement' do
      notification = described_class.create!(params)
      expect(notification.label).to eq(announcement.title)
    end

    it 'strips any html tags from the announcement title' do
      announcement.title = '<bad>title</bad>'
      notification = described_class.create!(params)
      expect(notification.label).to eq('title')
    end
  end

  describe '#redirect_type' do
    it 'returns :announcement' do
      notification = described_class.new
      expect(notification.redirect_type).to eq(:announcement)
    end
  end
end
