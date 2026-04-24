class MonthlyAssignmentList
  include IndividualAssignmentQueryable

  attr_accessor :month, :sections, :user, :year

  # 'total_time' is calculated as follows:
  # * Per each activity, sum the minutes to complete it from its
  #   'minutes_to_complete' field, or assume is 10 minutes if the
  #   activity has that field NULL.
  # * Since it is possible that the activity is assigned to multiple sections
  #   and hence many assignments records for the same activity are found,
  #   divide the sum of the minutes by the number of sections, in order to
  #   get the correct value in minutes.
  # * Finally, since the later operation returns a float value, cast it to
  #   an integer.
  SELECT_STATEMENT = <<~SQL.freeze
    assignments.id,
    assignments.due_date,
    assignments.section_id,
    assignments.custom_due_time,
    COUNT(DISTINCT(activities.id)) AS activity_count,
    CAST(
      SUM(IFNULL(activities.minutes_to_complete, 10)) /
      COUNT(DISTINCT(assignments.section_id))
      AS DECIMAL
    ) AS total_time
  SQL

  # The `coalesce` for the due date is added by apply_individual_assignment_filter.
  STUDENT_SELECT_STATEMENT = <<~SQL.freeze
    assignments.id,
    assignments.section_id,
    assignments.custom_due_time,
    COUNT(DISTINCT(activities.id)) AS activity_count,
    CAST(
      SUM(IFNULL(activities.minutes_to_complete, 10)) /
      COUNT(DISTINCT(assignments.section_id))
      AS DECIMAL
    ) AS total_time
  SQL

  def initialize(month, year, sections, user)
    self.month = month
    self.sections = sections
    self.user = user
    self.year = year
  end

  # For a student, if the section restricts how many days ahead of the due date
  # assignments are visible to the student, don't show unreleased assignments.
  def assignments
    if user.student?
      indexed_assignments.select { |_, entry| entry.due_date_released? }
    else
      indexed_assignments
    end
  end

  private def indexed_assignments
    assignment_scope.index_by(&:due_date)
  end

  private def assignment_scope
    if user.student?
      student_assignment_scope(user)
    else
      base_scope
    end
  end

  # Get the assigned activities to be displayed on the calendar by date
  # for the given sections.
  private def base_scope
    Assignment.select(SELECT_STATEMENT).by_type(Activity).where(
      'MONTH(assignments.due_date) = ? AND YEAR(assignments.due_date) = ?',
      month, year
    ).where(assignments: { section_id: sections }).group(:due_date)
  end

  # For a student, exclude any individually-assignable assignments that
  # are not individually assigned to the student.
  private def student_assignment_scope(user)
    due_date_coalesce = IndividualAssignmentQueryable::DUE_DATE_COALESCE
    scope = Assignment.select(STUDENT_SELECT_STATEMENT).by_type(Activity)

    apply_individual_assignment_filter(scope, user.id)
      .where(
        "MONTH(#{due_date_coalesce}) = ? AND YEAR(#{due_date_coalesce}) = ?",
        month, year
      )
      .where(assignments: { section_id: sections })
      .group(due_date_coalesce)
  end
end
