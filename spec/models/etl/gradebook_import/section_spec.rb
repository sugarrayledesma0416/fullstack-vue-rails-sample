describe Etl::GradebookImport::Section do
  let(:section_id) { 123 }
  let(:course_id) { create(:gb_course).id }
  let(:school_id) { create(:school).id }
  let(:new_attrs) do
    {
      'additional_info' => '',
      'class_days' => '1,3',
      'course_id' => course_id,
      'created_at' => '2012-06-01T09:48:16-04:00',
      'current_upto' => '2012-10-06',
      'days_to_show_assignment_due_date' => 3,
      'due_time' => '2000-01-01T23:59:00Z',
      'guid' => '1247',
      'hide_owner_name' => false,
      'id' => section_id,
      'instructor_id' => 830,
      'instructor_team_ids' => '830638',
      'is_archived' => false,
      'location' => nil,
      'name' => 'MDE section 1',
      'open_to_students' => true,
      'pronto_enabled' => false,
      'pronto_enabled_at' => nil,
      'request_id' => nil,
      'schedule' => nil,
      'school_id' => school_id,
      'setting' => nil,
      'sync_token' => 0,
      'time_zone' => 'Eastern Time (US & Canada)',
      'updated_at' => '2012-10-06T01:03:59-04:00'
    }
  end

  let(:update_attrs) { new_attrs.merge('name' => 'MDE section 1A', 'time_zone' => 'Mountain Time (US & Canada)') }

  describe 'import model action' do
    it 'creates a new gradebook section record when action is import' do
      gb_import_model = described_class.new(GradebookEngine::Section, 'import', new_attrs)
      new_section = gb_import_model.get_or_delete_record
      expect(new_section.id).to eql(section_id)
    end

    it 'throws uniqueness error saving new gradebook section record with existing M3 id' do
      gb_import_model = described_class.new(GradebookEngine::Section, 'import', new_attrs)
      new_section = gb_import_model.get_or_delete_record
      new_section.save!
      another_new_section = gb_import_model.get_or_delete_record
      expect { another_new_section.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook section record if it does not exist' do
      gb_import_model = described_class.new(GradebookEngine::Section, 'add_update', new_attrs)
      new_section = gb_import_model.get_or_delete_record
      expect(new_section.id).to eql(section_id)
    end

    it 'updates existing gradebook section record' do
      gb_import_model = described_class.new(GradebookEngine::Section, 'add_update', new_attrs)
      new_section = gb_import_model.get_or_delete_record
      new_section.save!
      new_section = ::GradebookEngine::Section.find(section_id)
      expect(new_section.name).to eql('MDE section 1')
      expect(new_section.time_zone).to eql('America/New_York')
      expect(new_section.school_id).to eq(school_id)
      gb_import_model = described_class.new(GradebookEngine::Section, 'add_update', update_attrs)
      updated_section = gb_import_model.get_or_delete_record
      updated_section.save!
      updated_section = ::GradebookEngine::Section.find(section_id)
      expect(updated_section.name).to eql('MDE section 1A')
      expect(updated_section.time_zone).to eql('America/Denver')
    end
  end
end
