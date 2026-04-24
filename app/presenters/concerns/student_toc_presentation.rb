module StudentTocPresentation
  include IndividualAssignmentQueryable

  extend ActiveSupport::Concern

  def grade_for(activity)
    grades[activity.id]
  end

  def has_sections?
    section.present? && !section.zero?
  end

  def assignments
    @assignments ||= apply_individual_assignment_filter(
      Assignment.by_section(*sections).by_activities(*activities),
      current_user.id
    )
  end

  # Defined to ensure compatiblity of code shared by instructor presenters.
  private def unassigned_sections(_)
    nil
  end

  private def activities_to_show_ids
    visible_activities_ids
  end

  private def notes_by_activity
    return {} unless section && course

    section.extend(StudentActivityPresenter::ActivityNotesSection)
    ActivityNote.where(
      activity_id: activities, user_id: section.responsible_instructor_ids
    ).group_by(&:activity_id)
  end

  private def grades
    @grades ||= GradebookEngine::GradebookAPI.user_strand_grades(
      section: section,
      strand_id: grading_strand,
      user: current_user
    )
  end

  def sections
    [section]
  end
end
