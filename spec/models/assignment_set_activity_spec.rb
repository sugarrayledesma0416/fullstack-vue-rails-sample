describe AssignmentSetActivity do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:assignment_set_rank) }
    it { is_expected.to validate_numericality_of(:assignment_set_rank).only_integer.is_greater_than(0) }

    context 'when an activity already exists in an assignment set' do
      let(:activity) { create(:activity) }
      let(:assignment_set) { create(:assignment_set) }

      let(:dupe_record) do
        build(
          :assignment_set_activity,
          activity: activity,
          assignment_set: assignment_set
        )
      end

      before do
        create(
          :assignment_set_activity,
          activity: activity,
          assignment_set: assignment_set
        )
      end

      it 'is invalid' do
        expect(dupe_record).not_to be_valid
      end

      it 'sets a uniqueness error' do
        dupe_record.valid?

        expect(dupe_record.errors[:activity_id]).to contain_exactly(
          'already exists in this Assignment Set'
        )
      end

      it 'is valid when the activity exists in a different assignment set' do
        assignment_set_2 = create(:assignment_set)

        assignment_set_activity = assignment_set_2.activities.create(activity: activity)

        expect(assignment_set_activity.errors[:activity_id]).to be_empty
      end
    end
  end

  describe '#assignment' do
    let(:activity) { create(:activity) }
    let(:assignment_set) { create(:assignment_set) }

    let!(:assignment_set_activity) do
      create(:assignment_set_activity, assignment_set: assignment_set, activity: activity)
    end

    context 'when an assignment with matching due_date and activity_id for ' \
            'the section exists' do
      let!(:assignment) do
        create(
          :assignment,
          assignable: activity,
          due_date: assignment_set.due_date,
          section: assignment_set.section
        )
      end

      it 'returns the first assignment' do
        expect(assignment_set_activity.assignment).to eq(assignment)
      end
    end

    context 'when an assignment with matching due_date and activity_id for ' \
            'the section does not exist' do
      it 'returns nil' do
        expect(assignment_set_activity.assignment).to eq(nil)
      end
    end
  end
end
