describe Lti::ContextLink do
  describe '.delete' do
    it 'deletes the record' do
      context_link = create(:lti_context_link)

      described_class.delete(context_link)

      expect(described_class).not_to exist(context_link.id)
    end

    it 'deletes the associated gradebook engine record', new_gb_sync: true do
      # Track Gradebook record existence before and after delete call.
      statuses = []

      context_link = create(:lti_context_link)
      statuses << GradebookEngine::Lti::ContextLink.exists?(context_link.id)

      described_class.delete(context_link)
      statuses << GradebookEngine::Lti::ContextLink.exists?(context_link.id)

      expect(statuses).to eq([true, false])
    end
  end
end
