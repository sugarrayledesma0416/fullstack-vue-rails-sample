class AssessmentsPresenter
  include AudienceLabeling
  include AssessmentHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::SanitizeHelper

  attr_accessor :program, :section, :user

  def initialize(program, section, user)
    self.program = program
    self.section = section
    self.user = user
  end

  def current_assessments
    current_assignments.map(&:assignable)
  end

  def current_assignments
    section.assignments.incomplete_released_non_practice_by_activity_list(
      program.assessments(sections: [section], current_user: user), user, section
    )
  end

  def to_do_and_finished_list
    { 'to-do': incomplete_list, 'finished': complete_list }
  end

  def sorted_current_assignments
    current_assignments.sort_by(&:due_date)
  end

  def past_assignments
    section.assignments.by_activity_list_completed_and_released(
      program.assessments(sections: [section], current_user: user), user, section
    )
  end

  def score_for(assignment)
    return unless section.non_zero?
    @user_section_grades ||= GradebookEngine::GradebookAPI.user_section_grades(
      user: user, section: section
    )
    @user_section_grades[assignment.assignable_id]
  end

  def grade_availability_description(assignment)
    return '' if assignment.assessment_grade_available?

    case assignment.grade_availability
    when :on_release
      "Your grade will be available when your #{instructor_label} releases it."
    when :on_grading
      'Your grade will be available when all students have been graded.'
    when :on_specific_date
      'Your grade will be available after ' +
        assignment.grades_available_at.strftime(
          "%a, %b #{assignment.grades_available_at.day.ordinalize} %I:%M %p."
        )
    when :on_due_date
      'Your grade will be available after ' +
        assignment.due_date.strftime(
          "%a, %b #{assignment.due_date.day.ordinalize} %I:%M %p."
        )
    when :never
      "Your #{instructor_label} has chosen not to show this grade online."
    end
  end

  private def incomplete_list
    sorted_current_assignments.map { |assignment| incomplete_data(assignment) }
  end

  private def complete_list
    past_assignments.map { |assignment| complete_data(assignment) }
  end

  private def assessment_link(activity, assignment)
    section_activity_path(id: activity.id, section_id: assignment.section_id)
  end

  private def complete_data(assignment)
    activity = assignment.assignable

    {
      due_date: assignment.due_date.strftime('%a %-m/%-d'),
      link: assessment_link(activity, assignment),
      title: format_assessment_assignment_title_text(activity)
    }
  end

  private def incomplete_data(assignment)
    activity = assignment.assignable

    {
      due_date: assignment.due_date_time.to_s(:short_ordinal),
      lesson: activity.lesson_display_name,
      link: assessment_link(activity, assignment),
      title: activity.concept_name
    }
  end

  private def instructor_label
    @instructor_label ||= audience_label(program.audience, :instructor)
  end

  private def percent_format(score)
    return '' if score.nil? || score.net_ratio.nil?
    number_to_percentage((score.net_ratio * 100).round(3), precision: 1)
  end
end
