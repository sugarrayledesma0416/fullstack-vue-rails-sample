describe GbEnrollmentMigrator do
  let(:m3_section) { create(:section_with_course) }
  let(:m3_enrollment) { create(:enrollment, section_id: m3_section.id) }
  let(:add_update_params) do
    {
      action: 'add_update',
      id: m3_enrollment.id,
      model_name: 'Enrollment'
    }
  end

  before do
    create(:gb_user, id: m3_enrollment.user_id)
    create(:gb_section, id: m3_enrollment.section_id)
  end

  describe 'add_update model action' do
    it 'creates a new gradebook section record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_enrollment = ::GradebookEngine::SectionUser.where(
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      ).first
      expect(new_gb_enrollment).to have_attributes(
        school_id: m3_section.course.school_id,
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      )
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Enrollment record' do
      gb_enrollment = ::GradebookEngine::SectionUser.new(
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      )
      gb_enrollment.save!
      gb_enrollment = ::GradebookEngine::SectionUser.where(
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      ).first
      expect(gb_enrollment).to have_attributes(
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      )
      gb_migrator = described_class.new(m3_enrollment.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      deleted_gb_enrollment = ::GradebookEngine::SectionUser.where(
        section_id: m3_enrollment.section_id,
        user_id: m3_enrollment.user_id
      ).first
      expect(deleted_gb_enrollment).to be_nil
    end
  end
end
