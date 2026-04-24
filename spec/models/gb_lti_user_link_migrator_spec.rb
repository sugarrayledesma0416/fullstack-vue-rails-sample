describe GbLtiUserLinkMigrator do
  let(:m3_lti_user_link) { create(:lti_user_link) }
  let(:add_update_args) do
    {
      action: 'add_update',
      id: m3_lti_user_link.id,
      model_name: 'Lti::UserLink'
    }
  end
  let(:migrator) { described_class.new(add_update_args) }

  describe '#update_object' do
    it 'creates a new gradebook Lti::UserLink record when none exists' do
      migrator.update_object

      gb_object = GradebookEngine::Lti::UserLink.find(m3_lti_user_link.id)
      expect(gb_object).to have_attributes(
        guid: m3_lti_user_link.guid,
        lti_platform_id: m3_lti_user_link.lti_platform_id,
        platform_user_id: m3_lti_user_link.platform_user_id,
        user_id: m3_lti_user_link.user_id
      )
    end

    it 'updates an existing gradebook Lti::UserLink record' do
      # Create the original gradebook record
      migrator.update_object

      new_attrs = {
        guid: SecureRandom.uuid,
        lti_platform_id: create(:lti_platform).id,
        platform_user_id: 'new-platform-user-id',
        user_id: create(:user).id
      }

      m3_lti_user_link.update!(new_attrs)

      migrator.update_object
      gb_object = GradebookEngine::Lti::UserLink.find(m3_lti_user_link.id)
      expect(gb_object).to have_attributes(new_attrs)
    end
  end
end
