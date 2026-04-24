describe BulkAssignmentCreator, core: true do
  let!(:activity) { create(:activity, instructor_revision_id: 1) }
  let(:section_1) { create(:section) }
  let(:section_2) { create(:section) }
  let(:source_section) { create(:section) }
  let(:course) { create(:course) }
  let(:category) { create(:category, name: 'Learn', weighting_percent: 100) }
  let(:rank) { 4 }
  let(:activity_schedule) do
    {
      Date.tomorrow.to_s => [
        {
          activities: [{ id: activity.id }]
        }
      ]
    }
  end
  let(:creator) { described_class.new([section_1, section_2], course, {}, source_section) }
  let(:activity_calendar) do
    [
      {
        due_date: Date.tomorrow.to_s,
        activity_id: activity.id,
        category: category,
        rank: rank,
        is_igc: true
      }
    ]
  end

  let(:attributes) do
    {
      section_id: section_1.id,
      assignable_id: activity.id,
      assignable_type: 'Activity',
      due_date: Date.tomorrow,
      category_id: category.id,
      rank: rank
    }
  end

  describe '#create' do
    before do
      allow(creator).to receive(:activity_calendar).and_return(activity_calendar)
    end

    it 'creates assignments' do
      expect { creator.create(activity_schedule) }.to change(Assignment, :count).by(2)
      expect(Assignment.where(attributes)).to exist
    end

    it 'creates course library activity records' do
      expect { creator.create(activity_schedule) }.to change(CourseLibraryActivity, :count).by(1)
    end

    it 'uses the same rank for an activity across all sections' do
      creator.create(activity_schedule)
      expect(
        Assignment.where(section_id: section_1.id, assignable_id: activity.id, rank: rank)
      ).to exist
      expect(
        Assignment.where(section_id: section_2.id, assignable_id: activity.id, rank: rank)
      ).to exist
    end

    context 'when the destination course is a template course' do
      let(:course) { create(:course_template) }

      it 'creates course library activity records if one does not exist for the course' do
        expect { creator.create(activity_schedule) }.to change(CourseLibraryActivity, :count).by(1)
      end

      context 'when a course library activity already exists for the course' do
        before do
          # record will not save unless we avoid using Course's default scope.
          Course.unscoped do
            create(:course_library_activity, course_id: course.id, activity_id: activity.id)
          end
        end

        it 'does not create another course library record' do
          expect { creator.create(activity_schedule) }.not_to change(CourseLibraryActivity, :count)
        end
      end
    end

    describe 'when the source section does not have custom ordered assignments' do
      it 'does not create assignment_set records' do
        expect { creator.create(activity_schedule) }.not_to change(AssignmentSet, :count)
      end

      it 'does not create assignment_set_activity records' do
        expect { creator.create(activity_schedule) }.not_to change(AssignmentSetActivity, :count)
      end
    end

    describe 'when the source section has custom ordered assignments' do
      let(:assignment_set_1) do
        create(
          :assignment_set,
          section: source_section,
          due_date: Date.tomorrow.strftime('%m/%d/%Y')
        )
      end

      before do
        create(
          :assignment_set_activity,
          activity: activity,
          assignment_set: assignment_set_1,
          assignment_set_rank: 1
        )
      end

      it 'creates an assignment_set record' do
        expect { creator.create(activity_schedule) }.to change(AssignmentSet, :count).by(2)
      end

      it 'creates an assignment_set_activity record' do
        expect { creator.create(activity_schedule) }.to change(AssignmentSetActivity, :count).by(2)
      end
    end

    describe 'when assignments have been created based on IGCs of a section ' \
             'that has assigned the source activity the shared IGC was based on, but ' \
             'not the actual shared IGC' do
      let(:shared_activity) do
        shared_activity = activity.dup
        shared_activity.title = 'Copy of '.concat(activity.title)
        shared_activity.save!
        shared_activity
      end
      let!(:shared_library_entry) do
        create(
          :shared_library_activity,
          source_activity: InstructorCreatedActivity.find(activity.id),
          activity: InstructorCreatedActivity.find(shared_activity.id),
          school: course.school
        )
      end
      let(:mock_assignment_1) { instance_double(Assignment, update!: true) }
      let(:mock_assignment_2) { instance_double(Assignment, update!: true) }
      # rubocop:disable RSpec/VerifiedDoubles
      let(:mock_course_library_activity) { double(CourseLibraryActivity).as_null_object }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        allow(Assignment).to receive(:where).with(
          assignable_id: activity.id,
          section: [section_1, section_2]
        ).and_return([mock_assignment_1, mock_assignment_2])
        allow(CourseLibraryActivity).to receive(:where).with(
          course_id: course.id,
          activity_id: activity.id
        ).and_return(mock_course_library_activity)
      end

      it 'updates the assignment to point to the shared IGC' do
        creator.create(activity_schedule)

        expect(mock_assignment_1).to have_received(:update!).with(assignable_id: shared_activity.id)
        expect(mock_assignment_2).to have_received(:update!).with(assignable_id: shared_activity.id)
      end

      it 'updates the course library activity to point to the shared IGC' do
        creator.create(activity_schedule)

        expect(mock_course_library_activity).to have_received(
          :update_attribute
        ).with(:activity_id, shared_activity.id)
      end

      it 'notifies if there has been an error' do
        assignment_instance = Assignment.new
        assignment_instance.errors.add(:base, 'Something bad happened when saving')
        expected_error = ActiveRecord::RecordInvalid.new(assignment_instance)
        allow(mock_assignment_1).to receive(:update!).and_raise(expected_error)
        allow(VHLMonitor).to receive(:notify)
        creator.create(activity_schedule)

        expect(VHLMonitor).to have_received(:notify).with(expected_error)
      end

      it 'does nothing if the shared IGC has been removed the shared library' do
        shared_library_entry.destroy!
        creator.create(activity_schedule)

        expect(mock_assignment_1).not_to have_received(:update!)
        expect(mock_assignment_2).not_to have_received(:update!)
        expect(mock_course_library_activity).not_to have_received(:update_attribute)
      end
    end
  end
end
