class StudentActivityPresenter
  include SharedActivityViewer
  include IndividualAssignmentQueryable

  def initialize(activity, user, section, answer_key_mode: false)
    super(activity, user, section, answer_key_mode:)
    self.notifications = populate_notifications
  end

  def populate_notifications
    @notifications ||= activity.notifications_by_user_and_section(@user, @section)
  end

  def unreviewed_notifications
    @unreviewed_notifications ||= notifications.reject(&:dismissed?)
  end

  def course
    section && section.course
  end

  def ruleset
    assignment.scoring_ruleset
  end

  def assignment
    return @assignment if defined?(@assignment)

    @assignment = apply_individual_assignment_filter(
      section.assignments.by_activities(activity),
      user.id
    ).first
  end

  def group_chat_selection_config
    assignment_config = @assignment&.group_chat_assignment_config
    if assignment_config
      { group_minimum: assignment_config.group_minimum - 1,
        group_maximum: assignment_config.group_maximum - 1 }
    else
      { group_minimum: activity.content_object.min_students_selection,
        group_maximum: activity.content_object.max_students_selection }
    end
  end

  def allows_inline_notes?
    ActiveSupport::Deprecation.warn("Use 'allows_expanded_notes?' instead.")
    allows_expanded_notes?
  end

  def allows_expanded_notes?
    !(activity.partner_chat? ||
      activity.virtual_chat? ||
      activity.video_virtual_chat? ||
      activity.solo_video_recording_or_included_in_multipart_activity? ||
      activity.group_chat?)
  end

  def activity_notes
    return [] unless course
    section.extend(ActivityNotesSection)
    @activity_notes ||= prepare_activity_notes
  end

  # current use is to determine whether or not there
  # are feedback items and a link to the feedback
  # panel should be shown in activity footer.
  def has_smartbook_attempt_with_feedback?
    activity.smart_book? && attempt&.smartbook_responses_with_feedback&.present?
  end

  def prepare_activity_notes
    activity_notes = activity.activity_notes.by_instructor(section.responsible_instructor_ids)
    if activity.virtual_chat? || activity.video_virtual_chat?
      activity_notes.each{|note| note.note_item_id = note.note_item_id.gsub(/_user_\d+/, "_user_#{@user.id}") }
    end
    activity_notes
  end
  private :prepare_activity_notes

  module ActivityNotesSection
    def responsible_instructor_ids
      (section_instructors.responsible.pluck(:user_id) + [course.owner_id]).uniq
    end
  end
end
