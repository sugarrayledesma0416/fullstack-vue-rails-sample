describe GbLessonMigrator do
  let (:unit) { create(:unit) }
  let(:m3_lesson)  { create(:lesson, unit: unit, label: 'Short name') }
  let(:add_update_params) { { model_name: 'Lesson', id: m3_lesson.id, action: 'add_update' } }

  describe 'add_update model action' do
    it 'creates a new gradebook section record if it does not exist' do
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      new_gb_lesson = ::GradebookEngine::Lesson.find(m3_lesson.id)
      expect(new_gb_lesson.name).to eql(m3_lesson.label)
      expect(new_gb_lesson.rank).to eql(m3_lesson.rank)
      expect(new_gb_lesson.unit_rank).to eql(m3_lesson.unit.rank)
      expect(new_gb_lesson.program_id).to eql(m3_lesson.program_id)
    end

    it 'updates existing gradebook Lesson record' do
      gb_lesson = ::GradebookEngine::Lesson.new()
      gb_lesson.id = m3_lesson.id
      gb_lesson.rank = m3_lesson.rank
      gb_lesson.unit_rank = m3_lesson.unit.rank
      gb_lesson.program_id = m3_lesson.unit.program_id
      gb_lesson.save
      gb_lesson = ::GradebookEngine::Lesson.find(m3_lesson.id)
      expect(gb_lesson.id).to eql(m3_lesson.id)
      expect(gb_lesson.rank).to eq(m3_lesson.rank)
      expect(gb_lesson.unit_rank).to eq(m3_lesson.unit.rank)
      expect(gb_lesson.program_id).to eq(m3_lesson.unit.program_id)
      m3_lesson.rank = m3_lesson.rank + 2
      m3_lesson.unit.program_id = m3_lesson.unit.program_id + 1
      m3_lesson.unit.save
      m3_lesson.save
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy
      updated_gb_lesson = ::GradebookEngine::Lesson.find(m3_lesson.id)
      expect(updated_gb_lesson.rank).to eql(m3_lesson.rank)
      # m3_lesson.unit.program_id = m3_lesson.unit.program_id - 1
      # GradebookEngine::Lesson.destroy(gb_lesson.id)
      new_gb_lesson = ::GradebookEngine::Lesson.new()
      new_gb_lesson.program_id = m3_lesson.unit.program_id
      new_gb_lesson.save
      expect(new_gb_lesson.program_id).to eq(m3_lesson.unit.program_id)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook Lesson record' do
      gb_lesson = ::GradebookEngine::Lesson.new()
      gb_lesson.id = m3_lesson.id
      gb_lesson.rank = m3_lesson.rank
      gb_lesson.unit_rank = m3_lesson.unit.rank
      gb_lesson.save
      gb_lesson = ::GradebookEngine::Lesson.find(m3_lesson.id)
      expect(gb_lesson.id).to eql(m3_lesson.id)
      gb_migrator = described_class.new(m3_lesson.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil
      expect{ ::GradebookEngine::Lesson.find(m3_lesson.id)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
