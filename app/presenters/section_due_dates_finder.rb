module SectionDueDatesFinder
  include IndividualAssignmentQueryable

  def section
    raise NotImplementedError
  end

  def current_due_day
    # we want current_due_day to be relative to the section time zone rather than the user's
    @current_due_day ||= Time.now.in_time_zone(section.time_zone).to_date
  end
  private :current_due_day

  def find_next_assignment_day
    find_next_assignment_days(current_due_day, 1).first
  end
  private :find_next_assignment_day

  def find_next_assignment_days(current_day, count)
    due_date_coalesce = Arel.sql(IndividualAssignmentQueryable::DUE_DATE_COALESCE)
    release_days = section.days_to_show_assignment_due_date
    apply_individual_assignment_filter(
      Assignment.by_section(section)
                .by_type(Activity),
      user.id
    )
      .where(["#{due_date_coalesce} >= ?", current_day])
      .where(release_days ? "#{due_date_coalesce} <='#{current_day + release_days}'" : nil)
      .distinct
      .limit(count)
      .order(due_date_coalesce)
      .pluck(due_date_coalesce)
  end
  private :find_next_assignment_days
end
