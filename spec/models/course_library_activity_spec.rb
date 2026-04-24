describe CourseLibraryActivity do
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor) }
  let(:activity) { create(:activity) }

  describe 'validations' do
    it 'requires a course_id' do
      expect(CourseLibraryActivity.new(course: nil, activity: activity)).not_to be_valid
    end

    it 'requires an activity_id' do
      expect(CourseLibraryActivity.new(course: course, activity: nil)).not_to be_valid
    end
  end

  describe "scopes" do
    describe '.by_course' do
      it 'returns activities by course' do
        course_1 = create(:course)
        course_2 = create(:course)
        library_activity_1 = create(:course_library_activity, course: course_1)
        library_activity_2 = create(:course_library_activity, course: course_2)
        expect(CourseLibraryActivity.by_course(course_1)).to match_array([library_activity_1])
      end
    end

    describe '.instructor_created' do
      it 'returns course library records for instructor created activities' do
        activity = create(:activity)
        created_activity = create(:activity, instructor_revision_id: 100)
        library_activity_1 = create(:course_library_activity, activity: activity)
        library_activity_2 = create(:course_library_activity, activity: created_activity)
        expect(CourseLibraryActivity.instructor_created).to match_array([library_activity_2])
      end
    end
  end

  describe '.hide_activity' do
    context 'when a matching record does not exist' do
      it 'creates a hidden record with the given course and activity' do
        expect{ CourseLibraryActivity.hide_activity(activity.id, course.id) }.to change(CourseLibraryActivity, :count).by(1)
        result = CourseLibraryActivity.last
        expect(result.activity).to eq(activity)
        expect(result.course).to eq(course)
        expect(result).to be_hidden
      end
    end

    context 'when a matching record exists' do
      it 'does not creates a new record' do
        CourseLibraryActivity.create(activity: activity, course: course, hidden: true)
        expect{ CourseLibraryActivity.hide_activity(activity.id, course.id) }.to_not change(CourseLibraryActivity, :count)
      end
    end

    context 'when an array is given' do
      context 'when a matching record does not exist' do
        it 'creates a new record for the records that do not match' do
          CourseLibraryActivity.create(activity: activity, course: course, hidden: true)
          another_activity = create(:activity)
          activities_ids = [activity.id, another_activity.id]
          expect{ CourseLibraryActivity.hide_activity(activities_ids, course.id) }.to change(CourseLibraryActivity, :count).by(1)
          result = CourseLibraryActivity.last
          expect(result.activity).to eq(another_activity)
          expect(result.course).to eq(course)
          expect(result).to be_hidden
        end
      end
    end

    context 'when the activity is assigned' do
      let(:section) { create(:section, course: course, instructor: instructor) }
      let(:another_course) { create(:course, owner: instructor) }
      let(:another_section) { create(:section, course: another_course, instructor: instructor) }

      context 'in the given course' do
        it 'unassigns the activity' do
          assignment = create(:assignment, assignable: activity, section: section)
          CourseLibraryActivity.hide_activity(activity.id, course.id)
          expect(activity.assignments).to be_empty
        end
      end

      context 'in another course' do
        it 'does not unassign the activity' do
          assignment_of_another_course = create(:assignment, assignable: activity, section: another_section)
          CourseLibraryActivity.hide_activity(activity.id, course.id)
          expect(activity.assignments).to eq([assignment_of_another_course])
        end
      end
    end

    context 'when an instructor created activity exists' do
      let(:instructor_created_activity) { create(:activity, instructor_revision_id: 1) }

      context 'when course library activity record exists, and it is not hidden' do
        it 'updates hidden as true' do
          CourseLibraryActivity.create(activity: instructor_created_activity, course: course, hidden: false)
          expect{ CourseLibraryActivity.hide_activity(instructor_created_activity.id, course.id) }.to_not change(CourseLibraryActivity, :count)
          expect(instructor_created_activity.course_library_activities.first).to be_hidden
        end
      end

      context 'when course library activity record does not exist' do
        it 'creates a new hidden course library activity record' do
          expect{ CourseLibraryActivity.hide_activity(instructor_created_activity.id, course.id) }.to change(CourseLibraryActivity, :count)
          expect(instructor_created_activity.course_library_activities.first).to be_hidden
        end
      end

      context 'when course library activity exists for a different course' do
        let(:another_course) { create(:course) }
        it 'should not be updated' do
          other_course_library_activity = CourseLibraryActivity.create(activity: instructor_created_activity, course: another_course, hidden: false)
          CourseLibraryActivity.hide_activity(instructor_created_activity.id, course.id)
          expect(other_course_library_activity.reload).not_to be_hidden
        end
      end

    end
  end

  describe '.unhide_activity' do
    context 'with regular activities' do
      context 'when activity is hidden' do
        it 'removes the activity record from the course_library_activities table' do
          CourseLibraryActivity.hide_activity(activity.id, course.id)
          expect{ CourseLibraryActivity.unhide_activity(activity.id, course.id) }.to change(CourseLibraryActivity, :count).by(-1)
        end
      end

      context 'when activity is not hidden' do
        it 'does not remove the record from the course_library_activities table' do
          expect{ CourseLibraryActivity.unhide_activity(activity.id, course.id) }.to_not change(CourseLibraryActivity, :count)
        end
      end
    end

    context 'with instructor created activities' do
      let(:instructor_created_activity) { create(:activity, instructor_revision_id: 1) }

      context 'when activity is hidden' do
        it 'changes the activity visibility without deleting the library record' do
          CourseLibraryActivity.create(activity: instructor_created_activity, course: course, hidden: true)
          expect{ CourseLibraryActivity.unhide_activity(instructor_created_activity.id, course.id) }.to_not change(CourseLibraryActivity, :count)
          expect(instructor_created_activity.course_library_activities.first).not_to be_hidden
        end
      end

      context 'when activity is not hidden' do
        it 'does not make any change to the visibility' do
          CourseLibraryActivity.create(activity: instructor_created_activity, course: course, hidden: false)
          expect{ CourseLibraryActivity.unhide_activity(instructor_created_activity.id, course.id) }.to_not change(CourseLibraryActivity, :count)
          expect(instructor_created_activity.course_library_activities.first).not_to be_hidden
        end
      end
    end
  end
end
