describe GbLtiContextLinkMigrator do
  let(:m3_lti_context_link) { create(:lti_context_link) }
  let(:add_update_args) do
    {
      action: 'add_update',
      id: m3_lti_context_link.id,
      model_name: 'Lti::ContextLink'
    }
  end
  let(:migrator) { described_class.new(add_update_args) }

  describe '#update_object' do
    it 'creates a new gradebook Lti::ContextLink record when none exists' do
      migrator.update_object

      gb_object = GradebookEngine::Lti::ContextLink.find(m3_lti_context_link.id)
      expect(gb_object).to have_attributes(
        context_id: m3_lti_context_link.context_id,
        context_label: m3_lti_context_link.context_label,
        context_title: m3_lti_context_link.context_title,
        deployment_id: m3_lti_context_link.deployment_id,
        guid: m3_lti_context_link.guid,
        line_items_url: m3_lti_context_link.line_items_url,
        lti_platform_id: m3_lti_context_link.lti_platform_id,
        platform_type: m3_lti_context_link.platform_type,
        section_id: m3_lti_context_link.section_id
      )
    end

    it 'updates an existing gradebook Lti::ContextLink record' do
      # Create the original gradebook record
      migrator.update_object

      new_attrs = {
        context_id: 'new-id',
        context_label: 'new context label',
        context_title: 'new context title',
        deployment_id: 'new deployment_id',
        guid: SecureRandom.uuid,
        line_items_url: 'https://new.line_items/url',
        lti_platform_id: create(:lti_platform).id,
        platform_type: 'new_platform_type',
        section_id: create(:section).id
      }

      m3_lti_context_link.update!(new_attrs)

      migrator.update_object
      gb_object = GradebookEngine::Lti::ContextLink.find(m3_lti_context_link.id)
      expect(gb_object).to have_attributes(new_attrs)
    end
  end
end
