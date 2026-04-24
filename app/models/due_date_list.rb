class DueDateList
  ASSIGNMENT_SELECT_STATEMENT = <<~SQL.freeze
    COALESCE(individual_assignments.due_date, assignments.due_date) as due_date,
    count(assignments.id) as 'assignment_count',
    SUM(IF(att.status_code IN (
      #{AttemptStatus::CODE_SUBMITTED},
      #{AttemptStatus::CODE_COMPLETED}
    ), 1, 0)) as 'activities_completed',
    SUM(
      IF(att.status_code = #{AttemptStatus::CODE_COMPLETED}, 0, activities.minutes_to_complete)
    ) as 'time_remaining'
  SQL

  attr_accessor :user, :section

  def initialize(user, section)
    self.user = user
    self.section = section
  end

  def assignment_groups(summary)
    @assignment_groups ||= {}
    @assignment_groups[summary.due_date] ||= DueDate.new(section.id, summary.due_date, user.id).assignment_groups
  end

  def assignment_summaries
    @assignment_summaries ||= AssignmentSummary.by_student_and_section(user.id, section)
  end

  def past_assignment_summaries
    @past_assignment_summaries ||= assignment_summaries.select { |as| section.date_in_past?(as.due_date) }.reverse
  end

  def future_assignment_summaries
    @future_assignment_summaries ||= assignment_summaries.select { |as| !section.date_in_past?(as.due_date) }
  end

  def incomplete_due_dates_count
    @incomplete_due_dates_count ||= past_assignment_summaries.select { |a| a.activities_remaining > 0  }.count
  end

  def first_incomplete_future_due_date
    unless defined?(@first_incomplete_future_due_date)
      summary = future_assignment_summaries.detect { |summary| summary.incomplete? }
      @first_incomplete_future_due_date = summary && summary.due_date
    end
    @first_incomplete_future_due_date
  end

  def first_incomplete_future_due_date?(summary)
    first_incomplete_future_due_date == summary.due_date
  end

  def first_incomplete_past_due_date?(summary)
    first_incomplete_past_due_date == summary.due_date
  end

  def first_incomplete_past_due_date
    unless defined?(@first_incomplete_past_due_date)
      summary = past_assignment_summaries.detect { |summary| summary.incomplete? }
      @first_incomplete_past_due_date = summary && summary.due_date
    end
    @first_incomplete_past_due_date
  end

  module AssignmentSummary
    extend IndividualAssignmentQueryable

    def activities_remaining
      assignment_count - activities_completed
    end

    def incomplete?
      activities_remaining > 0
    end

    def percentage_complete
      (activities_completed.to_f / assignment_count * 100).to_i
    end

    def estimated_completion_time
      format_hours_minutes(time_remaining, :short)
    end

    def formatted_due_date
      due_date.strftime('%m/%d/%y')
    end

    def todays?
      due_date == Date.today
    end

    def day_name
      due_date.strftime('%A')
    end

    def month_name
      due_date.strftime('%B')
    end

    def month_name_abbrev
      due_date.strftime('%b').upcase
    end

    def day
      due_date.strftime('%d')
    end

    def day_short
      due_date.strftime('%e')
    end

    def self.by_student_and_section(user_id, section)
      release_days = section.days_to_show_assignment_due_date

      scope = Assignment.select(ASSIGNMENT_SELECT_STATEMENT).joins(
        'LEFT OUTER JOIN attempts att on att.activity_id = assignments.assignable_id ' \
        'AND att.section_id = assignments.section_id ' \
        "AND att.user_id = #{user_id} " \
        "AND att.status_code <> #{AttemptStatus::CODE_RESET}"
      ).by_type(Activity).where(
        assignments: { section_id: section.id }
      ).where(
        if release_days
          [
            'COALESCE(individual_assignments.due_date, assignments.due_date) <= ?',
            Date.today + release_days
          ]
        end
      ).group(
        'COALESCE(individual_assignments.due_date, assignments.due_date)'
      )

      apply_individual_assignment_filter(scope, user_id).map do |assignment|
        assignment.extend(AssignmentSummary)
        assignment.extend(ApplicationHelper)
      end
    end

    def assignment_groups
      @assignment_groups
    end

    def assignment_groups=(value)
      @assignment_groups = value
    end
  end
end
