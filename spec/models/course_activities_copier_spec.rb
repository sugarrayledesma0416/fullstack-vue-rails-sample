describe CourseActivitiesCopier do
  let(:from_course) { create(:course) }
  let(:to_course) { create(:course) }
  let(:activity_1) { create(:activity, instructor_revision_id: 1) }
  let(:activity_2) { create(:activity, instructor_revision_id: 2) }
  let!(:created_activity_to_share) { create(:activity, instructor_revision_id: 100) }
  let!(:shared_activity) { create(:activity, instructor_revision_id: 100) }

  describe '#copy' do
    it 'copies activities not present in course' do
      create(:course_library_activity, course: from_course, activity: activity_1)
      create(:course_library_activity, course: from_course, activity: activity_2)
      described_class.new(from_course.id, to_course.id).copy
      course_activities = CourseLibraryActivity.where(course_id: to_course.id)
      expect(course_activities.map(&:activity)).to eq(
        [activity_1, activity_2])
    end

    it 'does not copy activities already present in course' do
      create(:course_library_activity, course: from_course, activity: activity_1)
      create(:course_library_activity, course: from_course, activity: activity_2)
      create(:course_library_activity, course: to_course, activity: activity_1)
      described_class.new(from_course.id, to_course.id).copy
      course_activities = CourseLibraryActivity.where(course_id: to_course.id)
      expect(course_activities.map(&:activity)).to eq(
        [activity_1, activity_2])
    end

    it 'copies only shared activities if shared_only is true' do
      create(:course_library_activity, course: from_course, activity: activity_1)
      create(:course_library_activity, course: from_course, activity: activity_2)
      create(:course_library_activity,
             course: from_course,
             activity: shared_activity,
             hidden: false)
      create(:shared_library_activity,
             source_activity_id: created_activity_to_share.id,
             activity_id: shared_activity.id,
             school_id: from_course.school_id,
             is_shared: true)
      described_class.new(from_course.id, to_course.id, shared_only: true).copy
      course_activities = CourseLibraryActivity.where(course_id: to_course.id)
      expect(course_activities.map(&:activity)).to eq([shared_activity])
    end
  end
end
