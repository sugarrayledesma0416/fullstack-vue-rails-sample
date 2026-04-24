describe AssignmentSetUpdater do
  let(:instructor) { create(:instructor) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:course) { create(:course, owner: instructor) }
  let(:due_date) { course.start_date + 7.days }

  describe '#update' do
    let(:activity_1) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:activity_3) { create(:activity) }

    let(:assignment_set) do
      create(:assignment_set, due_date: due_date, section: section)
    end

    let(:set_attrs) do
      {
        id: assignment_set.id,
        activities: [
          { activity_id: activity_1.id, assignment_set_rank: 1 }
        ]
      }
    end

    let(:updater) do
      described_class.new(assignment_set.id, set_attrs)
    end

    context 'when all specified activity attrs pass validation,' do
      it 'updates all the assignment sets' do
        updater.update

        expect(assignment_set.activities.reload).to contain_exactly(
          have_attributes(set_attrs[:activities].first)
        )
      end

      it 'returns an empty error array' do
        expect(updater.update.errors).to be_empty
      end
    end

    context 'when the attrs for the specified activities are invalid' do
      before do
        set_attrs[:activities][0][:assignment_set_rank] = ''
      end

      it 'does not save the specified activity' do
        updater.update

        expect(assignment_set.activities.reload).to be_empty
      end

      it 'returns populated errors' do
        expect(updater.update.errors).to contain_exactly(
          'Activities could not be updated because one or more records ' \
          'failed validation'
        )
      end
    end

    context 'when an assignment set has existing activities,' do
      before do
        create(
          :assignment_set_activity,
          activity: activity_1,
          assignment_set: assignment_set,
          assignment_set_rank: 1
        )

        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set,
          assignment_set_rank: 2
        )
      end

      it 'removes those activities from the set if an empty activities ' \
        'array is specified for the set' do
        set_attrs[:activities] = []

        updater.update

        expect(assignment_set.activities.reload).to be_empty
      end

      it 'removes activities from the set that are not specified for that set' do
        set_attrs[:activities] = [
          { activity_id: activity_3.id, assignment_set_rank: 1 }
        ]

        updater.update

        expect(assignment_set.activities).to contain_exactly(
          have_attributes(activity_id: activity_3.id, assignment_set_rank: 1)
        )
      end

      it 'updates the activity ranks if activities are specified with ' \
         'ranks different to their current ranks' do
        set_attrs[:activities] = [
          { activity_id: activity_1.id, assignment_set_rank: 2 }
        ]

        updater.update

        expect(
          assignment_set.activities.find_by(
            activity_id: activity_1.id
          )
        ).to have_attributes(assignment_set_rank: 2)
      end

      context 'when activities are specified that are not already in the set' do
        before do
          set_attrs[:activities] = [
            { activity_id: activity_1.id, assignment_set_rank: 2 },
            { activity_id: activity_3.id, assignment_set_rank: 1 }
          ]
        end

        it 'adds new assignment_set_activity records' do
          updater.update

          expect(assignment_set.activities).to contain_exactly(
            have_attributes(activity_id: activity_1.id, assignment_set_rank: 2),
            have_attributes(activity_id: activity_3.id, assignment_set_rank: 1)
          )
        end
      end

      context 'when the attrs for the any specified activity are invalid' do
        before do
          set_attrs[:activities] = [
            { activity_id: activity_1.id, assignment_set_rank: '' },
            { activity_id: activity_3.id, assignment_set_rank: 1 }
          ]
        end

        it 'does not save any of the specified activities' do
          updater.update

          expect(assignment_set.activities).to contain_exactly(
            have_attributes(activity_id: activity_1.id, assignment_set_rank: 1),
            have_attributes(activity_id: activity_2.id, assignment_set_rank: 2)
          )
        end

        it 'returns populated errors' do
          expect(updater.update.errors).to contain_exactly(
            'Activities could not be updated because one or more records ' \
            'failed validation'
          )
        end
      end
    end
  end
end
