describe Etl::GradebookImport::Lesson do
  let(:new_attrs) do
    {
      'created_at' => '2012-05-30T09:36:03-04:00',
      'id' => 13,
      'label' => "<b>Lesson 1</b>",
      'name' => "Lección 1 | Hey, what's up?",
      'rank' => 0,
      'unit_id' => 5,
      'unit_rank' => 2,
      'updated_at' => '2012-05-30T09:36:03-04:00',
      'use_type' => 'Lesson'
    }
  end
  let(:unit) { create(:unit) }
  let(:update_attrs) do
    new_attrs.merge('name' => "Lección 1 | Hola, ¿qué tal?",
                    'rank' => 1,
                    'unit_id' => 4,
                    'unit_rank' => 3,
                    'label' => '<b>Lección 1</b>')
  end

  describe 'import model action' do
    it 'creates a new gradebook lesson record when action is import' do
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'import',
                                            new_attrs)
      new_lesson = gb_import_model.get_or_delete_record
      expect(new_lesson.id).to eql(13)
    end

    it 'new gradebook lesson record falls back to M3 name if M3 label is missing' do
      new_attrs['label'] = nil
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'import',
                                            new_attrs)
      new_lesson = gb_import_model.get_or_delete_record
      expect(new_lesson.id).to eql(13)
      expect(new_lesson.name).to eql("Lección 1 | Hey, what's up?")
    end

    it 'throws uniqueness error saving new gradebook lesson record with existing M3 id' do
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'import',
                                            new_attrs)
      new_lesson = gb_import_model.get_or_delete_record
      new_lesson.save
      another_new_lesson = gb_import_model.get_or_delete_record
      expect { another_new_lesson.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook lesson record if it does not exist' do
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'import',
                                            new_attrs)
      new_lesson = gb_import_model.get_or_delete_record
      expect(new_lesson.id).to eql(13)
      expect(new_lesson.unit_id).to eq(5)
    end

    it 'updates existing gradebook lesson record' do
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'add_update',
                                            new_attrs)
      new_lesson = gb_import_model.get_or_delete_record
      new_lesson.save
      new_lesson = ::GradebookEngine::Lesson.find(13)
      expect(new_lesson.name).to eql("Lesson 1")
      expect(new_lesson.rank).to eq 0
      expect(new_lesson.unit_rank).to eq 2
      expect(new_lesson.unit_id).to eq 5
      gb_import_model = described_class.new(GradebookEngine::Lesson,
                                            'add_update',
                                            update_attrs)
      updated_lesson = gb_import_model.get_or_delete_record
      updated_lesson.save
      updated_lesson = ::GradebookEngine::Lesson.find(13)
      expect(updated_lesson.name).to eql('Lección 1')
      expect(updated_lesson.rank).to eq 1
      expect(updated_lesson.unit_rank).to eq 3
      expect(updated_lesson.unit_id).to eq 4
    end
  end
end
