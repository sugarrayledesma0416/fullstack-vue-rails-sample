describe CourseDataDeleter do
  let(:course) { create(:course) }
  let(:other_course) { create(:course) }
  let(:deleter) { described_class.new(course.id) }

  describe '#delete_course_data' do
    it 'deletes all activity notes associated with the course' do
      create(:activity_note, focused_course: course)
      create(:activity_note, focused_course: other_course)
      deleter.delete_course_data
      expect(ActivityNote.where(focused_course_id: course.id)).to be_empty
      expect(ActivityNote.where(focused_course_id: other_course.id)).to_not be_empty
    end

    it 'deletes all assignment filters associated with the course' do
      create(:assignment_filter, course: course)
      create(:assignment_filter, course: other_course)
      deleter.delete_course_data
      expect(AssignmentFilter.where(course_id: course.id)).to be_empty
      expect(AssignmentFilter.where(course_id: other_course.id)).not_to be_empty
    end

    it 'deletes all categories associated with the course' do
      category = create(:category, course: course)
      other_category = create(:category, course: other_course)
      create(:scoring_ruleset, category: category)
      create(:scoring_ruleset, category: other_category)
      deleter.delete_course_data
      expect(Category.where(course_id: course.id)).to be_empty
      expect(Category.where(course_id: other_course.id)).to_not be_empty
      expect(ScoringRuleset.where(category_id: category.id)).to be_empty
      expect(ScoringRuleset.where(category_id: other_category.id)).not_to be_empty
    end

    it 'deletes all course library activities associated with the course' do
      create(:course_library_activity, course: course)
      create(:course_library_activity, course: other_course)
      deleter.delete_course_data
      expect(CourseLibraryActivity.where(course_id: course.id)).to be_empty
      expect(CourseLibraryActivity.where(course_id: other_course.id)).to_not be_empty
    end

    it 'deletes all external activities associated with the course' do
      # No factory for external activities.
      ExternalActivity.create(course_id: course.id)
      ExternalActivity.create(course_id: other_course.id)
      deleter.delete_course_data
      expect(ExternalActivity.where(course_id: course.id)).to be_empty
      expect(ExternalActivity.where(course_id: other_course.id)).to_not be_empty
    end

    it 'deletes all sections associated with the course' do
      section = create(:section, course: course)
      expect(SectionDataDeleter).to receive(:new).with(section.id).and_call_original
      allow_any_instance_of(SectionDataDeleter).to receive(:delete_section_data)
      deleter.delete_course_data
    end

    it 'deletes the course' do
      deleter.delete_course_data
      expect(Course.find_by(id: course.id)).to be_nil
      expect(Course.find_by(id: other_course.id)).to_not be_nil
    end
  end
end
