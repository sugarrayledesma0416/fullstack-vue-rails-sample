describe Cartridge::LineItemDestination do
  let(:section) { create(:section) }
  let(:user) { create(:user) }
  let(:activity) { create(:activity) }
  let(:line_item_url) { "https://lms.example.org/api/lti/courses/#{SecureRandom.uuid}/line_item/#{rand(1..99)}" }
  let!(:line_item_destination) { create(:cartridge_line_item_destination) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:section) }
  it { is_expected.to belong_to(:activity) }

  it { is_expected.to validate_presence_of(:line_item_url) }

  describe '#find_by_user_section_activity' do
    it 'returns the expected instance' do
      retrieved_line_item_destination =
        described_class.find_by_user_section_activity(
          user: line_item_destination.user,
          section: line_item_destination.section,
          activity: line_item_destination.activity
        )
      expect(retrieved_line_item_destination).to eq line_item_destination
    end
  end

  describe '#add_or_update' do
    it 'adds a new instance' do
      expect do
        described_class.add_or_update(
          user: user,
          section: section,
          activity: activity,
          line_item_url: line_item_url
        )
      end.to change(described_class, :count).by(1)
      expect(described_class.last).to have_attributes(
        user_id: user.id,
        section_id: section.id,
        activity_id: activity.id,
        line_item_url: line_item_url
      )
    end

    it 'finds an existing instance' do
      expect do
        described_class.add_or_update(
          user: line_item_destination.user,
          section: line_item_destination.section,
          activity: line_item_destination.activity,
          line_item_url: line_item_url
        )
      end.to change(Cartridge::ScoreDestination, :count).by(0)
    end

    it 'finds an existing instance and updates the line_item_url' do
      new_line_item_url = 'https://lms.example.org/api/lti/courses/1/line_item/2'
      described_class.add_or_update(
        user: line_item_destination.user,
        section: line_item_destination.section,
        activity: line_item_destination.activity,
        line_item_url: new_line_item_url
      )
      expect(line_item_destination.reload.line_item_url).to eq(new_line_item_url)
    end
  end
end
