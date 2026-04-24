class AssignmentValidator
  # possible reasons why an activity can't be assigned
  UNASSIGNABLE_CHAT_DISABLED_AT_SCHOOL_LEVEL = :unassignable_chat_disabled_at_school_level
  UNASSIGNABLE_CHAT_ACTIVITY = :unassignable_chat_activity
  UNASSIGNABLE_DRAFT_ACTIVITY = :unassignable_draft_activity
  UNASSIGNABLE_AI_VIRTUAL_CHAT = :unassignable_ai_virtual_chat
  UNASSIGNABLE_MISSING_LICENSE = :unassignable_missing_license
  UNASSIGNABLE_TEACHER_EDITION = :unassignable_teacher_edition

  ACTIVITY_TYPES_TO_HIDE_WITH_SCHOOL_CHAT_SUPPORT_DISABLED = [
    'partner_chat',
    'group_chat'
  ].freeze

  attr_reader :instructor, :course, :activities, :valid_activities, :invalid_activities

  def initialize(instructor, course, activities)
    @instructor = instructor
    @course = course
    @activities = activities
    @valid_activities = []
    @invalid_activities = []
  end

  # Tests if the instructor has the required licenses to assign the
  # activities.
  def validate
    @valid_activities, @invalid_activities = activities.partition do |activity|
      assignable?(activity)
    end
  end

  def program
    @program ||= activities.first && activities.first.program
  end

  def invalid_activity_assignments
    @invalid_activity_assignments ||= invalid_activities.map do |activity|
      activity_assignment = ActivityAssignment.new(activity, instructor, program,
                                                   { :course_id => course.id })
      activity_assignment.errors.add(:base, "#{activity.title} was not updated because you do not have access to it")
      activity_assignment
    end
  end

  def assignable?(activity)
    if school_chat_support_disabled? &&
      ACTIVITY_TYPES_TO_HIDE_WITH_SCHOOL_CHAT_SUPPORT_DISABLED.include?(activity.activity_type)
      false
    elsif activity.ai_virtual_chat? && !ai_virtual_chat_enabled?
      false
    elsif (activity.partner_chat? || activity.group_chat?) && course&.chat_disabled?
      false
    elsif activity.draft?
      false
    else
      license_group_ids.include?(activity.license_group_id)
    end
  end

  def ai_virtual_chat_enabled?
    @ai_virtual_chat_enabled ||= course&.ai_virtual_chat_level?
  end

  def unassignable_reason(activity)
    if activity.is_a?(EReaderItem)
      UNASSIGNABLE_TEACHER_EDITION
    elsif school_chat_support_disabled? &&
          ACTIVITY_TYPES_TO_HIDE_WITH_SCHOOL_CHAT_SUPPORT_DISABLED.include?(activity.activity_type)
      UNASSIGNABLE_CHAT_DISABLED_AT_SCHOOL_LEVEL
    elsif (activity.partner_chat? || activity.group_chat?) && course&.chat_disabled?
      UNASSIGNABLE_CHAT_ACTIVITY
    elsif activity.draft?
      UNASSIGNABLE_DRAFT_ACTIVITY
    elsif activity.ai_virtual_chat? && !ai_virtual_chat_enabled?
      UNASSIGNABLE_AI_VIRTUAL_CHAT
    elsif license_group_ids.exclude?(activity.license_group_id)
      UNASSIGNABLE_MISSING_LICENSE
    end
  end

  def any_assignable?(activities)
    activities.any? do |activity|
      assignable?(activity)
    end
  end

  def license_group_ids
    @license_group_ids ||= course_licenses.map { |cl| cl.license_group.id }.uniq
  end

  def course_licenses
    @course_licenses ||= course_and_any_sections? ? Maestro::CourseLicense.all(course.guid) : []
  end

  private def course_and_any_sections?
    course && course.sections_count > 0
  end

  private def school_chat_support_disabled?
    course&.school&.has_chat_support_disabled?
  end
end
