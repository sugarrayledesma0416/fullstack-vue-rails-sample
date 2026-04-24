module AssessmentAvailabilityChecker
  def assessment_release_link_hover_text(activity)
    if grades_available?(activity)
      'Availability cannot be changed after results have been released.'
    else
      ''
    end
  end

  def grades_available?(activity)
    assignments_for_activity(activity).any? do |assignment|
      time_zone = assignment.section.time_zone
      available = assignment.grades_available_at
      available && time_for_zone(time_zone) >= available
    end
  end

  def release_link_assignment(activity)
    @assignment = assignments_for_activity(activity).first
  end

  def release_link_text(activity, type)
    (show_release?(release_link_assignment(activity), type) ? 'Release' : 'Hide')
  end

  private def availability_status(activity, status_method)
    assignments = assignments_for_activity(activity)
    return '' if assignments.empty?

    if assignments.have_different_values_for?(status_method)
      'Varies'
    else
      assignments.first.send(status_method) ? 'Yes' : 'No'
    end
  end

  private def show_release?(assignment, type)
    return '' unless assignment

    case type
    when 'assessment_release' then assignment.show_at.blank?
    when 'grade_release'      then assignment.grades_available_at.blank?
    end
  end
end
