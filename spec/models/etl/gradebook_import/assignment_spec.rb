describe Etl::GradebookImport::Assignment do
  let(:strand) { create(:gb_strand) }
  let(:section) { create(:gb_section) }
  let(:lesson) { create(:gb_lesson) }
  let(:activity) { create(:gb_activity) }
  let(:category) { create(:gb_category) }
  let(:new_attrs) do
    {
      'answer_availability' => nil,
      'answers_available_at' => nil,
      'assignable_id' => activity.id,
      'assignable_type' => 'Activity',
      'assigned_assessment_detail_id' => nil,
      'category_id' => category.id,
      'current' => true,
      'concept_id' => strand.id,
      'created_at' => '2012-06-07T10:16:10-04:00',
      'custom_due_time' => nil,
      'due_date' => '2012-06-11',
      'grade_availability' => nil,
      'grades_available_at' => nil,
      'id' => 1233,
      'lesson_id' => lesson.id,
      'rank' => 0,
      'section_id' => section.id,
      'show_assessment' => nil,
      'show_at' => nil,
      'study_schedule_id' => nil,
      'track_group_id' => nil,
      'updated_at' => '2012-06-12T01:00:07-04:00'
    }
  end

  let(:update_attrs) { new_attrs.merge('custom_due_time' => '19:00:00') }
  let(:original_details) { {} }
  let(:modified_details) { { 'custom_due_time' => '19:00:00' } }

  describe 'import model action' do
    it 'creates a new gradebook assignment record when action is import' do
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', new_attrs
      )
      new_assignment = gb_import_model.get_or_delete_record

      expect(
        new_assignment.attributes.slice(
          'activity_id',
          'section_id'
        ).values
      ).to eql(
        [
          activity.id,
          section.id
        ]
      )
    end

    it 'converts due_date to expected day_id and week_id' do
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', new_attrs
      )
      new_assignment = gb_import_model.get_or_delete_record

      expect(
        new_assignment.attributes.slice(
          'day_id',
          'week_id'
        ).values
      ).to eql(
        [
          Date.new(2012, 6, 11),
          Date.new(2012, 6, 10)
        ]
      )
    end

    it 'throws uniqueness error saving new gradebook course record with existing primary key' do
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', new_attrs
      )
      new_assignment = gb_import_model.get_or_delete_record
      new_assignment.save!
      another_new_assignment = gb_import_model.get_or_delete_record
      expect { another_new_assignment.save! }.to raise_error(
        ActiveRecord::RecordNotUnique
      )
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook assignment record if it does not exist' do
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'add_update', new_attrs
      )
      new_assignment = gb_import_model.get_or_delete_record
      expect(new_assignment.activity_id).to eql(activity.id)
      expect(new_assignment.section_id).to eql(section.id)
    end

    it 'updates existing gradebook assignment record' do
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'add_update', new_attrs
      )
      new_assignment = gb_import_model.get_or_delete_record
      new_assignment.save!
      new_assignment = ::GradebookEngine::Assignment.where(
        activity_id: activity.id, section_id: section.id
      ).first
      expect(new_assignment.details).to eql(original_details)
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'add_update', update_attrs
      )
      updated_assignment = gb_import_model.get_or_delete_record
      updated_assignment.save!
      updated_assignment = ::GradebookEngine::Assignment.where(
        activity_id: activity.id, section_id: section.id
      ).first
      expect(updated_assignment.details).to eql(modified_details)
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook assignment record' do
      other_activity = create(:gb_activity)
      other_section = create(:gb_section)
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', new_attrs
      )
      new_assignment1 = gb_import_model.get_or_delete_record
      new_assignment1.save!
      another_assignment_attrs = new_attrs.merge(
        'section_id' => other_section.id,
        'assignable_id' => other_activity.id
      )
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', another_assignment_attrs
      )
      new_assignment_2 = gb_import_model.get_or_delete_record
      new_assignment_2.save!
      another_assignment_attrs = new_attrs.merge(
        'section_id' => section.id,
        'assignable_id' => other_activity.id
      )
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'import', another_assignment_attrs
      )
      new_assignment_3 = gb_import_model.get_or_delete_record
      new_assignment_3.save!
      expect(::GradebookEngine::Assignment.all.count).to eq 3
      delete_attrs = new_attrs.merge(
        'section_id' => other_section.id,
        'assignable_id' => other_activity.id
      )
      gb_import_model = described_class.new(
        GradebookEngine::Assignment, 'delete', delete_attrs
      )
      deleted_assignment = gb_import_model.get_or_delete_record
      expect(deleted_assignment).to be_nil
      expect(::GradebookEngine::Assignment.all.count).to eq 2
    end
  end
end
