

module AttemptHelper
  include ActionView::Helpers::TagHelper

  def format_scoring_ruleset(scoring_ruleset, language_code = '')
    assessment_ruleset(scoring_ruleset, language_code)
  end

  def assessment_ruleset(scoring_ruleset, language_code = '')

    unless scoring_ruleset.nil?
      content_tag(:ul, class: 'strictness-list') do
        scoring_ruleset.respected_features_list.select do |rule|
          language_code != 'zh' || rule[:text]  == 'punctuation'
        end.each { |rule| format_rule(rule) }
      end
    end
  end

  private def format_rule(rule)
    msg = {'accents' => 'Extra or missing accent marks',
           'capitalization' => 'Incorrect capitalization',
           'punctuation' => 'Punctuation errors' }
    msg_suffix = 'affect your score.'

    rule_text = [msg[rule[:text]], (rule[:status] ? 'WILL NOT' : 'WILL'), msg_suffix].join(' ')
    rule_classes = "#{(rule[:status] ? 'inactive' : 'active')} #{rule[:text]}"
    concat(content_tag(:li, rule_text, :class => rule_classes, :title => rule[:text].titleize))
  end

  private def status_string(status)
    case status
    when :unopened then ''
    when :opened then 'opened'
    when :incomplete then 'started'
    when :completed then 'viewed'
    else
      ''
    end
  end

  def activity_link(grade, activity)
    css_class = grade.late? ? 'late_score activity_link' : 'activity_link'
    link_to("#{grade.formatted_score}%",
            section_activity_path(grade.section.id, activity),
            class: css_class)
  end

  def format_grade(grade, activity)
    # Formats a GradebookEngine::AssignmentGrade score.

    # NOTE: This method assumes that the grade exists and is for
    #   an assignment that the student has submitted.

    if grade.pending? || grade.partial_pending?
      'Pending'
    else
      # Show grade only if the student has submitted it.
      activity_link(grade, activity)
    end
  end

  def format_attempt_status_from_gradebook(status:, presenter:, activity:)
    # If the activity is gradeable and has been submitted,
    #   format the grade.

    if activity.gradable?
      grade = presenter.grade_for(activity)
      if grade && grade.submitted?
        return format_grade(grade, activity)
      end
    end

    # In all other cases, fall through to the status string.
    status_string(status)
  end

  def format_attempt_status(presenter:, activity:)
    status = presenter.attempt_status[activity.id]
    if presenter.has_sections?
      format_attempt_status_from_gradebook(status: status,
                                           presenter: presenter,
                                           activity: activity)
    end
  end
end
