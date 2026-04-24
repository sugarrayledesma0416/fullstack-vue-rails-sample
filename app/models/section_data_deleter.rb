class SectionDataDeleter
  attr_reader :section_id

  def initialize(section_id)
    @section_id = section_id
  end

  def delete_section_data
    delete_announcements
    delete_assessment_student_time_limits
    delete_assignments
    delete_attempts
    delete_enrollments
    delete_feedback_items
    delete_forums
    delete_help_requests
    delete_notifications
    delete_section_instructors
    delete_student_spotcheck_counts
    delete_worksets
    delete_section
  end

  def delete_announcements
    Announcement.joins(:announcement_sections).where(
      announcement_sections: { section_id: section_id }
    ).destroy_all
  end

  def delete_assessment_student_time_limits
    AssessmentStudentTimeLimit.where(section_id: section_id).destroy_all
  end

  def delete_assignments
    # Avoid callbacks by using delete_all
    Assignment.where(section_id: section_id).delete_all
  end

  def delete_attempts
    # There are so many attempts that we don't want to use
    # destroy_all, which will load each record into memory.
    Attempt.where(section_id: section_id).delete_all
  end

  def delete_enrollments
    Enrollment.where(section_id: section_id).destroy_all
  end

  def delete_feedback_items
    FeedbackItem.where(section_id: section_id).destroy_all
  end

  def delete_forums
    Forum.where(section_id: section_id).destroy_all
  end

  def delete_help_requests
    HelpRequest.where(section_id: section_id).destroy_all
  end

  def delete_notifications
    Notification.where(section_id: section_id).destroy_all
  end

  def delete_section_instructors
    SectionInstructor.where(section_id: section_id).destroy_all
  end

  def delete_student_spotcheck_counts
    StudentSpotcheckCount.where(section_id: section_id).destroy_all
  end

  def delete_worksets
    Workset.where(section_id: section_id).destroy_all
  end

  def delete_section
    Section.find(section_id).delete
  end
end
