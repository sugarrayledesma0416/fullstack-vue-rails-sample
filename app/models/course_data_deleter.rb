class CourseDataDeleter
  attr_reader :course_id

  def initialize(course_id)
    @course_id = course_id
  end

  def delete_course_data
    delete_activity_notes
    delete_assignment_filters
    delete_categories
    delete_course_library_activities
    delete_external_activities
    delete_sections
    delete_course
  end

  def delete_activity_notes
    ActivityNote.where(focused_course_id: course_id).destroy_all
  end

  def delete_assignment_filters
    AssignmentFilter.where(course_id: course_id).destroy_all
  end

  def delete_categories
    # Scoring rulesets are associated with a category so delete those
    # as well.
    category_ids = Category.where(course_id: course_id).pluck(:id)
    ScoringRuleset.where(category_id: category_ids).destroy_all
    # Avoid callbacks by using delete_all
    Category.where(course_id: course_id).delete_all
  end

  def delete_course_library_activities
    CourseLibraryActivity.where(course_id: course_id).destroy_all
  end

  def delete_external_activities
    ExternalActivity.where(course_id: course_id).destroy_all
  end

  def delete_sections
    Section.where(course_id: course_id).pluck(:id).each do |section_id|
      SectionDataDeleter.new(section_id).delete_section_data
    end
  end

  def delete_course
    Course.find(course_id).delete
  end
end
