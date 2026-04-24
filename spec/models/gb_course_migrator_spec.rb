describe GbCourseMigrator do
  let (:program) { create(:program) }
  let (:current_events_unit) { create(:current_events_unit, :program => program) }
  let(:m3_course)  { create(:course, :name => 'M3 Course', :program => program) }
  let(:add_update_params) { { :model_name => 'Course', :id => m3_course.id, :action => 'add_update' } }

  before do
    allow(program).to receive(:current_events_unit).and_return(current_events_unit)
  end

  describe 'add_update model action' do
    it 'creates a new gradebook course record if it does not exist' do
      gb_migrator = GbCourseMigrator.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(new_gb_course.name).to eql(m3_course.name)
      expect(new_gb_course.school_id).to eq(m3_course.school_id)
      expect(new_gb_course.first_unit_id).to eql(m3_course.first_unit_id)
      expect(new_gb_course.last_unit_id).to eql(m3_course.last_unit_id)
      expect(new_gb_course.current_events_unit_id).to eql(m3_course.program.current_events_unit.id)
    end

    it 'updates existing gradebook course record' do
      gb_course = ::GradebookEngine::Course.new()
      gb_course.name = 'Existing M3 Course'
      gb_course.id = m3_course.id
      gb_course.save
      gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(gb_course.name).to eql('Existing M3 Course')
      m3_course.name = 'Modified M3 Course'
      m3_course.save
      gb_migrator = GbCourseMigrator.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(updated_gb_course.name).to eql('Modified M3 Course')
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook course record' do
      gb_course = ::GradebookEngine::Course.new()
      gb_course.name = 'Existing M3 Course'
      gb_course.id = m3_course.id
      gb_course.save
      gb_course = ::GradebookEngine::Course.find(m3_course.id)
      expect(gb_course.name).to eql('Existing M3 Course')
      gb_migrator = GbCourseMigrator.new(m3_course.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect{::GradebookEngine::Course.find(m3_course.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
