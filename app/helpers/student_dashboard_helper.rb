module StudentDashboardHelper
  def assignment_group_path(group, due_date, user)
    # Support showing instructors a preview of the student dashboard, but
    # with all the "Start" buttons for each workset disabled.
    if user.instructor?
      '#'
    elsif group.is_assessment
      section_activity_path(group.section_id, group.assessment_id)
    else
      section_assignment_bank_path(assignment_bank_params(group, due_date))
    end
  end

  private def assignment_bank_params(group, due_date)
    {
      assignment_day: due_date,
      concept_id: group.concept_id,
      rank_range: group.rank_range,
      section_id: group.section_id
    }
  end
end
