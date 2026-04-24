class ClassworkFilter
  include ::TimeHandler
  include AssignmentSorter
  include IndividualAssignmentQueryable

  # NOTE: apply_assignment_set_scope needs to be applied to a scope only after
  # apply_individual_assignment_filter has been applied. If the individual
  # assignment filter is applied later, its `select(assignments.*)` will
  # override the `COALESCE(....) as rank` at the end of this select statement.
  ASSIGNMENT_SELECT_STATEMENT = <<~SQL.squish.freeze
    assignments.id,
    assignments.assignable_id,
    assignments.assignable_type,
    COALESCE(asa.assignment_set_rank, assignments.rank) as rank
  SQL

  attr_accessor :lesson_id

  def initialize(params = {})
    self.lesson_id = params[:lesson_id]
    @classwork = params[:classwork]
    @assignment_day = params[:assignment_day]
    @concept = params[:concept]
    @category = params[:category]
    @rank_range = params[:rank_range]
    @include_all_assignments = params[:include_all_assignments]
    @included_activity_id = params[:included_activity_id]
    @user = @classwork.user
    @section = @classwork.section
  end

  def assignments
    @assignments ||= filtered_assignments
  end

  def create_workset
    @classwork.new_workset(activities.map(&:id))
  end

  def has_assignments?
    assignments.present?
  end

  def first_activity_for_student(user)
    return activities.first unless @include_all_assignments

    # could do this with a single query on attempt to get completed ids, then loop through activity ids
    # to find the first one not in the list (which preserves order)
    # completed_activity_ids = Attempt.where(user_id: user, section_id: @classword.section, activity_id: activity_ids,
    #                                        status_code: AttemptStatus::CODE_COMPLETED).pluck(:activity_id)
    # first_incomplete_activity_id = activity_ids.detect{|activity_id| !completed_activity_ids.include?(activity_id)}
    # first_incomplete_activity_id || activity_ids.first

    # or
    # could do this as a left outer join on attempts, with one query for all activity ids.
    # to maintain sort order, could use:
    # .order( "find_in_set( activities.id, '#{ activity_ids.join(',') }' )" )
    # avoids looping over activitiy ids. limit 1 grabs you the first.

    activity = activities.detect do |activity|
      attempt = Attempt.find_by_student_section_and_activity(user, @classwork.section, activity)
      attempt.nil? || !attempt.complete?
    end
    activity || activities.first
  end

  def activities
    return @activities if defined?(@activities)

    # Assessments should not appear in workset if neither a concept or
    # lesson is specified.
    included_assignments = if @concept || lesson_id
                             assignments
                           else
                             assignments.reject { |a| a.assignable.concept.assessment }
                           end
    @activities = sort_assignments(included_assignments).map(&:assignable)
  end
  private :activities

  def sort_assignments(assignments)
    return [] if assignments == []
    sort_by_due_date_and_rank(assignments)
  end
  private :sort_assignments

  def filtered_assignments
    if @rank_range
      if @concept
        base_assignment_scope.where(
          activities: { concept_id: @concept.id }
        ).where(
          [
            'COALESCE(individual_assignments.due_date, assignments.due_date) = ?',
            @assignment_day
          ]
        ).where(
          'COALESCE(asa.assignment_set_rank, assignments.rank) BETWEEN ? AND ?',
          rank_range_limit.first,
          rank_range_limit.last
        )
      else
        []
      end
    else
      if @assignment_day == 'overdue'
        filtered_incomplete_past_due_assignments
      elsif @include_all_assignments
        @classwork.all_assignments_for_date(@assignment_day, @concept, @category)
      else
        incomplete_assignments_for_date(@assignment_day, @concept, @category)
      end
    end
  end
  private :filtered_assignments

  private def filtered_incomplete_past_due_assignments
    if lesson_id
      incomplete_past_due_assignments.where(activities: { lesson_id: lesson_id })
    else
      incomplete_past_due_assignments
    end
  end

  def rank_range_limit()
    @rank_range_limit ||= @rank_range.split('..').map(&:to_i)
  end
  private :rank_range_limit

  private def base_assignment_scope
    @base_assignment_scope ||= apply_assignment_set_scope(
      apply_individual_assignment_filter(
        Assignment.by_type(Activity)
        .preload(assignable: :concept)
        .where(
          section_id: @section.id
        ),
        @user.id
      )
    )
  end

  private def incomplete_past_due_assignments
    base_assignment_scope.joins(
      'LEFT JOIN attempts ON attempts.activity_id = assignments.assignable_id ' \
      "AND attempts.user_id = #{@user.id} " \
      'AND attempts.section_id = assignments.section_id ' \
      "AND attempts.status_code IN (#{AttemptStatus::CODE_SUBMITTED}, " \
      "#{AttemptStatus::CODE_COMPLETED})"
    ).where(
      [
        'COALESCE(individual_assignments.due_date, assignments.due_date) < ?',
        date_for_zone(@section.time_zone)
      ]
    ).where(attempts: { id: nil })
  end

  private def apply_assignment_set_scope(scope)
    scope.select(ASSIGNMENT_SELECT_STATEMENT).joins(AssignmentSorter::ASSIGNMENT_JOINS).order(
      Arel.sql(AssignmentSorter::ASSIGNMENT_ORDER)
    )
  end

  def incomplete_assignments_for_date(due_date, concept = nil, category = nil)
    scope = apply_individual_assignment_filter(
      Assignment.incomplete_by_user(@user)
      .preload(assignable: :concept)
      .joins(
        'LEFT JOIN activities ON activities.id = assignments.assignable_id'
      ),
      @user.id
    )

    scope = apply_assignment_set_scope(scope)

    scope = scope.where(category_id: category) if category
    scope = scope.where('activities.concept_id = ?', concept.id) if concept
    scope.select(ASSIGNMENT_SELECT_STATEMENT).where(section_id: @section).where(
      [
        'COALESCE(individual_assignments.due_date, assignments.due_date) = ?',
        due_date
      ]
    ).sort_by(&:rank)
  end
end
