describe Etl::GradebookImport::IndividualAssignment do
  let(:section) { create(:gb_section) }
  let(:activity) { create(:gb_activity) }
  let(:user) { create(:gb_user) }

  let(:new_attrs) do
    {
      'activity_id' => activity.id,
      'due_date' => '2012-06-11',
      'id' => 1233,
      'section_id' => section.id,
      'user_id' => user.id
    }
  end

  let(:update_attrs_new_due_date) { new_attrs.merge('due_date' => '2012-06-18') }
  let(:update_attrs_nil_due_date) { new_attrs.merge('due_date' => nil) }
  let(:updated_day_id) { Date.new(2012, 6, 18) }
  let(:updated_week_id) { Date.new(2012, 6, 17) }

  describe 'import model action' do
    it 'creates a new gradebook assignment record when action is import' do
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', new_attrs
      )
      new_individual_assignment = gb_import_model.get_or_delete_record

      expect(
        new_individual_assignment.attributes.slice(
          'activity_id',
          'section_id',
          'user_id'
        ).values
      ).to eql(
        [
          activity.id,
          section.id,
          user.id
        ]
      )
    end

    it 'converts due_date to expected day_id and week_id' do
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', new_attrs
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

    it 'throws uniqueness error saving new gradebook individual assignment record ' \
       'with existing primary key' do
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', new_attrs
      )
      new_individual_assignment = gb_import_model.get_or_delete_record
      new_individual_assignment.save!
      another_new_individual_assignment = gb_import_model.get_or_delete_record
      expect { another_new_individual_assignment.save! }.to raise_error(
        ActiveRecord::RecordNotUnique
      )
    end
  end

  describe 'add_update model action' do
    it 'creates a new gradebook individual assignment record if it does not exist' do
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'add_update', new_attrs
      )
      new_individual_assignment = gb_import_model.get_or_delete_record

      expect(
        new_individual_assignment.attributes.slice(
          'activity_id',
          'section_id',
          'user_id'
        ).values
      ).to eql(
        [
          activity.id,
          section.id,
          user.id
        ]
      )
    end

    describe 'updating existing gradebook individual assignment record' do
      it 'updates day_id and week_id correctly for new due date' do
        gb_import_model = described_class.new(
          GradebookEngine::IndividualAssignment, 'add_update', new_attrs
        )
        new_assignment = gb_import_model.get_or_delete_record
        new_assignment.save!
        new_assignment = ::GradebookEngine::IndividualAssignment.where(
          activity_id: activity.id, section_id: section.id
        ).first
        gb_import_model = described_class.new(
          GradebookEngine::IndividualAssignment, 'add_update', update_attrs_new_due_date
        )
        updated_assignment = gb_import_model.get_or_delete_record
        updated_assignment.save!
        updated_assignment = ::GradebookEngine::IndividualAssignment.where(
          activity_id: activity.id, section_id: section.id
        ).first

        expect(
          updated_assignment.attributes.slice(
            'day_id',
            'week_id'
          ).values
        ).to eq(
          [
            updated_day_id,
            updated_week_id
          ]
        )
      end

      it 'updates day_id and week_id to be null for new due date == nil' do
        gb_import_model = described_class.new(
          GradebookEngine::IndividualAssignment, 'add_update', new_attrs
        )
        new_assignment = gb_import_model.get_or_delete_record
        new_assignment.save!
        new_assignment = ::GradebookEngine::IndividualAssignment.where(
          activity_id: activity.id, section_id: section.id
        ).first
        gb_import_model = described_class.new(
          GradebookEngine::IndividualAssignment, 'add_update', update_attrs_nil_due_date
        )
        updated_assignment = gb_import_model.get_or_delete_record
        updated_assignment.save!
        updated_assignment = ::GradebookEngine::IndividualAssignment.where(
          activity_id: activity.id, section_id: section.id
        ).first

        expect(
          updated_assignment.attributes.slice(
            'day_id',
            'week_id'
          ).values
        ).to eq(
          [
            nil,
            nil
          ]
        )
      end
    end
  end

  describe 'delete model action' do
    it 'deletes an existing gradebook individual assignment record' do
      other_activity = create(:gb_activity)
      other_section = create(:gb_section)
      other_user = create(:gb_user)

      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', new_attrs
      )

      new_assignment1 = gb_import_model.get_or_delete_record
      new_assignment1.save!
      another_assignment_attrs = new_attrs.merge(
        'section_id' => other_section.id,
        'assignable_id' => other_activity.id,
        'user_id' => other_user.id
      )

      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', another_assignment_attrs
      )

      new_assignment_2 = gb_import_model.get_or_delete_record
      new_assignment_2.save!
      another_assignment_attrs = new_attrs.merge(
        'section_id' => section.id,
        'assignable_id' => other_activity.id,
        'user_id' => other_user.id
      )
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'import', another_assignment_attrs
      )
      new_assignment_3 = gb_import_model.get_or_delete_record
      new_assignment_3.save!
      expect(::GradebookEngine::IndividualAssignment.all.count).to eq 3
      delete_attrs = new_attrs.merge(
        'section_id' => other_section.id,
        'assignable_id' => other_activity.id,
        'user_id' => other_user.id
      )
      gb_import_model = described_class.new(
        GradebookEngine::IndividualAssignment, 'delete', delete_attrs
      )
      deleted_assignment = gb_import_model.get_or_delete_record
      expect(deleted_assignment).to be_nil
      expect(::GradebookEngine::IndividualAssignment.all.count).to eq 2
    end
  end
end
