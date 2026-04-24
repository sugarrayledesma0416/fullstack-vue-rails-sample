# "Common" means shared between Supersite Junior and non-Supersite Junior
module TocPresenterCommon
  attr_accessor :current_user, :course

  def access_guardian
    @access_guardian ||= AccessGuardian.new(current_user, program)
  end

  def due_date_info_for(activity_id)
    @due_dates_by_activity ||= due_dates_by_activity
    @due_dates_by_activity[activity_id]
  end

  def activity_assignments(activity_id)
    @assignments_by_activity ||= assignments.group_by(&:assignable_id)
    @assignments_by_activity[activity_id] || []
  end

  def nothing_assigned?(activities)
    activities.none? do |activity|
      due_date_info_for(activity.id).activity_is_assigned?
    end
  end

  private def activities_ids_hash
    @activities_ids_hash ||= ::Services::TocActivityList.all_for_toc_location(
      current_topic,
      sections: self&.sections || [section],
      current_user:
    )
  end

  private def visible_activities_ids
    activities_ids_hash
  end

  private def due_dates_by_activity
    activities.each_with_object({}) do |activity, due_date_handlers|
      due_date_handlers[activity.id] =
        AssignmentDueDateHandler.new(
          activity_assignments(activity.id),
          unassigned_sections(activity.id)
        )
    end
  end

  class AssignmentDueDateHandler
    include ActionView::Helpers::TagHelper
    include DateTimeHelper
    include AssignmentHelper
    include MultipleDueDatesChecker

    attr_reader :activity_assignments, :unassigned_sections

    def initialize(activity_assignments, unassigned_sections = nil)
      @activity_assignments = activity_assignments
      @unassigned_sections = unassigned_sections
    end

    def assignment_id
      activity_assignments.first&.id
    end

    def individually_assigned?
      activity_assignments.any?(&:individually_assignable)
    end

    def activity_id
      activity_assignments.first&.assignable_id
    end

    def instructor_due_date_info
      if !assigned_on_multiple_dates?(activity_assignments) && unassigned_sections.blank?
        assignment_due_date
      else
        'varies'
      end
    end

    def due_date_info(attempt_status)
      format_due_date_if_late(assignment_due_date, assignment_due_date , attempt_status)
    end

    def due_date_released?
      # For student use case,
      # one activity will belong to only single assignment and we can safely
      # fetch assignment due date remaining from first assignment
      error_text = 'Length of activity_assignments should not be greater than 1.'\
                  'Method "due_date_released?" is for student use case only.'
      raise error_text if activity_assignments.length > 1

      activity_assignments&.first&.due_date_released?
    end

    def activity_is_assigned?
      activity_assignments.present?
    end

    def assignment_due_date
      format_date_time(activity_assignments.first.due_date, :today_or_date)
    end
    private :assignment_due_date
  end

  def has_note?(activity)
    @notes_by_activity ||= notes_by_activity
    @notes_by_activity[activity.id].present?
  end

  def program_language
    language_code = program&.language_code
    # Chinese uses English lesson names
    if language_code && language_code != 'zh'
      language_code
    else
      'en'
    end
  end

  def attempt_status
    @attempt_status ||= Attempt.status_for_activities(
      current_user, [section], activities
    )
  end

  def show_google_classroom_button?
    course = current_focus&.course
    enabled_in_course = course&.share_to_google_classroom
    enabled_in_school = course&.school&.can_share_to_google_classroom?
    enabled_in_course && enabled_in_school ? true : false
  end
end
