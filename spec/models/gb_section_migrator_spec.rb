describe GbSectionMigrator do
  let(:m3_section) { create(:section_with_course, name: 'Section 1') }
  let(:add_update_params) do
    { model_name: 'Section', id: m3_section.id, action: 'add_update' }
  end

  describe 'add_update model action' do
    it 'creates a new gradebook section record if it does not exist' do
      create(:gb_course, id: m3_section.course_id)
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_section = ::GradebookEngine::Section.find(m3_section.id)
      expect(new_gb_section.name).to eql(m3_section.name)
      expect(new_gb_section.school_id).to eq(m3_section.course.school_id)
    end

    it 'updates existing gradebook section record' do
      create(:gb_course, id: m3_section.course_id)
      gb_section = ::GradebookEngine::Section.new(
        course_id: m3_section.course_id,
        id: m3_section.id,
        name: 'Existing M3 Section'
      )
      gb_section.save!
      gb_section = ::GradebookEngine::Section.find(m3_section.id)
      expect(gb_section.name).to eql('Existing M3 Section')
      m3_section.name = 'Modified M3 Section'
      m3_section.save!
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_section = ::GradebookEngine::Section.find(m3_section.id)
      expect(updated_gb_section.name).to eql('Modified M3 Section')
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Section record' do
      create(:gb_course, id: m3_section.course_id)
      gb_section = ::GradebookEngine::Section.new(
        course_id: m3_section.course_id,
        id: m3_section.id,
        name: 'Existing M3 Section'
      )
      gb_section.save!
      gb_section = ::GradebookEngine::Section.find(m3_section.id)
      expect(gb_section.name).to eql('Existing M3 Section')
      gb_migrator = described_class.new(m3_section.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect do
        ::GradebookEngine::Section.find(m3_section.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
