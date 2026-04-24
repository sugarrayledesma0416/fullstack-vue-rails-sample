module InstructorTocPresentation
  extend ActiveSupport::Concern
  include UnassignedSectionsLookup

  CONTENT_FILTER = [
    ['All Content', 'all_content'],
    ['My Content', 'my_content'],
    ['My Drafts', 'my_drafts']
  ].freeze

  INDIVIDUAL_DUE_DATES_ASSIGNMENT_SELECT = <<~SQL.freeze
    assignments.*,
    SUM(
      IF(individual_assignments.due_date IS NOT NULL
         AND assignments.individually_assignable is true
         AND assignments.due_date != individual_assignments.due_date,
         1,
         0)
    ) >= 1 as multiple_due_dates
  SQL

  INDIVIDUAL_DUE_DATES_ASSIGNMENT_JOIN = <<~SQL.freeze
    LEFT OUTER JOIN individual_assignments
         ON individual_assignments.activity_id = assignments.assignable_id
         AND individual_assignments.section_id = assignments.section_id
  SQL

  def assignments
    @assignments ||= Assignment.activity_assignments(sections, activities)
                               .select(INDIVIDUAL_DUE_DATES_ASSIGNMENT_SELECT)
                               .joins(INDIVIDUAL_DUE_DATES_ASSIGNMENT_JOIN)
                               .group('assignments.id')
  end

  def activity_creator(activity)
    return unless activity.instructor_id

    @instructor_names_by_id ||= {}
    instructor_name = @instructor_names_by_id[activity.instructor_id]
    unless instructor_name
      instructor_name = User.unscoped.find(activity.instructor_id).full_name
      @instructor_names_by_id[activity.instructor_id] = instructor_name
    end
    instructor_name
  end

  def allowed_to_create_content?
    Policy::Course::CreateEdit.new(current_user)
                              .allowed_to_create_content_in_course?(
                                current_focus.course
                              )
  end

  def content_filter
    CONTENT_FILTER
  end

  def other_instructor_activity?(activity)
    activity.instructor_id && activity.instructor_id != current_user.id
  end

  def portfolio_enabled?(activity)
    current_focus.course&.activity_share_to_portfolio?(
      activity.activity_type
    )
  end

  def sections
    current_focus.sections
  end

  private def activities_to_show_ids
    visible_activities_ids
  end

  private def notes_by_activity
    current_user.activity_notes.by_activity(activities).group_by(&:activity_id)
  end
end
