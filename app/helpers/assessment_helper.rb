module AssessmentHelper
#<%= activity.lesson_label %> | <%= activity.concept.name %>
  def format_assessment_assignment_title(assignment, section, score,  html_options = {})
    if assignment.assessment_grade_available? && (score && !score.pending?)
      link_to format_assessment_assignment_title_text(assignment.assignable), section_activity_path(section, assignment.assignable)
    else
      content_tag 'span', format_assessment_assignment_title_text(assignment.assignable), html_options.reject{ |option_name, option_value| option_value.blank? }
    end
  end

  def format_assessment_assignment_score_as_link(assignment, section, score, html_options = {})
    if assignment.assessment_grade_available? && (score && !score.pending?)
      link_to format_current_score(score), section_activity_path(section, assignment.assignable) unless format_current_score(score).empty?
    else
      content_tag 'span', 'Pending', html_options.reject{ |option_name, option_value| option_value.blank? }
    end
  end

  def format_assessment_assignment_title_text(activity)
    sanitize(activity.student_display_title, tags: %w[span], attributes: %w[lang])
  end

  def pretty_print_time(seconds)
    f_hours = (seconds / 3600).round
    f_minutes = ((seconds - (f_hours * 3600)) / 60).round
    f_seconds = (seconds - (f_hours * 3600) - (f_minutes * 60)) % 3600

    [].tap do |output|
      output << pluralize(f_hours, 'hour', 'hours') if f_hours > 0
      output << pluralize(f_minutes, 'minute', 'minutes') if f_minutes > 0 
      output << pluralize(f_seconds, 'second', 'seconds') if f_seconds > 0
    end.join(' ')
  end
end
