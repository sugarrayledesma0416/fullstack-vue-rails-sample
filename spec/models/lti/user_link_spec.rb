describe Lti::UserLink do
  describe '.delete' do
    it 'deletes the record' do
      user_link = create(:lti_user_link)

      described_class.delete(user_link)

      expect(described_class).not_to exist(user_link.id)
    end

    it 'deletes the associated gradebook engine record', new_gb_sync: true do
      # Track Gradebook record existence before and after delete call.
      statuses = []

      user_link = create(:lti_user_link)
      statuses << GradebookEngine::Lti::UserLink.exists?(user_link.id)

      described_class.delete(user_link)
      statuses << GradebookEngine::Lti::UserLink.exists?(user_link.id)

      expect(statuses).to eq([true, false])
    end
  end
end
