describe Lti::Platform do
  describe '.delete' do
    it 'deletes the record' do
      platform = create(:lti_platform)

      described_class.delete(platform)

      expect(described_class).not_to exist(platform.id)
    end

    it 'deletes the associated gradebook engine record', new_gb_sync: true do
      # Track Gradebook record existence before and after delete call.
      statuses = []

      platform = create(:lti_platform)
      statuses << GradebookEngine::Lti::Platform.exists?(platform.id)

      described_class.delete(platform)
      statuses << GradebookEngine::Lti::Platform.exists?(platform.id)

      expect(statuses).to eq([true, false])
    end
  end

  describe 'rostering_transition_from_ra?' do
    it 'returns false when rostering_transition_from is empty' do
      platform = build(:lti_rostering_platform, rostering_transition_from: nil)

      expect(platform).not_to be_rostering_transition_from_ra
    end

    it 'returns true when rostering_transition_from is RA' do
      platform = build(:lti_rostering_platform, rostering_transition_from: 'RA')

      expect(platform).to be_rostering_transition_from_ra
    end
  end

  describe 'rostering_transition_from_clever?' do
    it 'returns false when rostering_transition_from is empty' do
      platform = build(:lti_rostering_platform, rostering_transition_from: nil)

      expect(platform).not_to be_rostering_transition_from_clever
    end

    it 'returns true when rostering_transition_from is Clever' do
      platform = build(:lti_rostering_platform, rostering_transition_from: 'Clever')

      expect(platform).to be_rostering_transition_from_clever
    end
  end
end
