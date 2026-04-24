class InstructorGradingTasksPresenter
  include IndividualAssignmentQueryable

  attr_accessor :activities_count, :current_task
  attr_reader :section_ids, :student_ids

  def initialize(opts = {})
    @current_task = opts[:current_task]
    @section_ids = opts[:section_ids]
    @student_ids = opts[:student_ids]
  end

  def task_set(task)
    task_lists[task]
  end

  # Seems unused, target for deletion.
  def empty?
    task_lists.empty?
  end

  def tasklist_count(task)
    task_lists[task].assignment_count || 0
  end

  # TODO: The student_by_student_presenter currently instantiates this
  # presenter and uses it to call one method from the current grading task:
  # students_for_activity(activity)
  # The grading_tasks/assignments_index view loads all 4 in order to show
  # the counts per task, and displays the activities from the first task, but
  # then uses AJAX to re-load all the data but display only the results from
  # one particular task.
  # It may be worth having a way to load data from only one task at a time
  # for use in the student_by_student presenter, and have the ajax load only
  # instantiate the needed task. But we'd also need a way to get the data for
  # all 4 tasks just to show the numbering in the assignments_index view.
  # In the interests of least change, will continue to generate all 4 sets.
  private def task_lists
    @task_lists ||= {
      GradingTask::UPCOMING_GRADING => upcoming_grading_set,
      GradingTask::NEEDS_GRADING => needs_grading_set,
      GradingTask::ALREADY_GRADED => already_graded_set,
      GradingTask::UNASSIGNED_ACTIVITIES => unassigned_activities_set
    }
  end

  private def upcoming_grading_set
    @upcoming_grading_set ||= GradingTaskSet.new(
      reviewable_scores: results.select(&:upcoming_grading?),
      submitted_scores: results.select(&:assigned?),
      student_ids: student_ids_by_activity
    )
  end

  private def needs_grading_set
    @needs_grading_set ||= GradingTaskSet.new(
      reviewable_scores: results.select(&:needs_grading?),
      submitted_scores: results.select(&:assigned?),
      student_ids: student_ids_by_activity
    )
  end

  private def already_graded_set
    @already_graded_set ||= GradingTaskSet.new(
      exclusions: [upcoming_grading_set, needs_grading_set]
                  .flat_map(&:unique_activities).uniq,
      reviewable_scores: results.select(&:already_graded?),
      submitted_scores: results.select(&:assigned?),
      student_ids: student_ids_by_activity
    )
  end

  private def unassigned_activities_set
    @unassigned_activities_set ||= GradingTaskSet.new(
      reviewable_scores: results.select(&:unassigned_pending?),
      submitted_scores: results.select(&:unassigned?),
      student_ids: unassigned_student_ids_by_activity
    )
  end

  private def unassigned_student_ids_by_activity
    activity_ids.each_with_object({}) do |activity_id, memo|
      assigned_student_ids = student_ids_by_activity[activity_id] || []
      memo[activity_id] = student_ids - assigned_student_ids
    end
  end

  private def student_ids_by_activity
    @student_ids_by_activity ||= populate_students_by_activity
  end

  # If assignments are not individually-assignable, then the student_ids
  # for those activities are all the students enrolled in the section.
  # If they are individually-assignable, the student_ids are only the students
  # enrolled in the section for whom the activity is individually assigned.
  private def populate_students_by_activity
    individual_assignment_scope.each_with_object({}) do |entry, memo|
      memo[entry.activity_id] ||= []
      if !entry.individually_assignable? || entry.individually_assigned?
        memo[entry.activity_id] << entry.user_id
      end
    end
  end

  # individual_assignment_grading_set_scope is defined in
  # module IndividualAssignmentQueryable
  private def individual_assignment_scope
    individual_assignment_grading_set_scope(activity_ids, section_ids)
  end

  private def activity_ids
    @activity_ids ||= @results.map(&:activity_id)
  end

  private def results
    # The return value of the call to grading_set_results will be a collection
    # containing a single record per student_section_activity combo.
    # A student with scores in two different sections will have 2 entries.
    # Unsubmitted activities will be ignored.
    # The gradebook query uses a customized .select to return fields from
    # joined tables, which are not normally found on ScoreAction records.
    # The records will respond to:
    # attributes: activity_id, due_date, section_id, user_id
    # predicates: assigned?, credit_only?, due?, instructor_graded?, pending?
    # Extends each instance with some predicate methods specific to the
    # logic in this presenter.
    # As an optimization, looks up the activities for all results and
    # stashes the activity for each record in an accessor.
    return @results if defined?(@results)

    @results = GradebookEngine::GradebookAPI.grading_set_results(
      section_ids:, user_ids: student_ids
    )
    activity_lookup = Activity.where(id: activity_ids)
                              .includes(lesson: :unit).index_by(&:id)
    @results.each do |record|
      record.extend(TaskSetPredicates)
      record.stashed_activity = activity_lookup[record.activity_id]
    end
  end

  class GradingTaskSet
    attr_reader :student_ids

    def initialize(opts)
      @exclusions = opts[:exclusions] || []
      @reviewable_scores = opts[:reviewable_scores]
      @submitted_scores = opts[:submitted_scores]
      @student_ids = opts[:student_ids]
    end

    # Public, consumed by grading_tasks/_activities_index.html.erb
    # This method will return misleading results if there are assignments
    # in different sections with different due dates, as it returns
    # the assignment matching just one of the scores for the activity.
    def due_date_for_activity(activity)
      scores_for_activity(activity).map(&:due_date).compact.first
    end

    # Public, consumed by grading_tasks/_activities_index.html.erb
    def submission_counts_for_activity(activity)
      {
        assigned_count: (student_ids[activity.id] || []).size,
        submitted_count: submitted_count[activity.id]
      }
    end

    # Public, consumed by grading_tasks/_activities_index.html.erb
    def number_to_be_graded(activity)
      scores_for_activity(activity).count
    end

    # Public, consumed by student_by_student presenter.
    # Misnamed, as it returns ids not instances of Student.
    def students_for_activity(activity)
      scores_for_activity(activity).map(&:user_id)
    end

    # Public, consumed by InstructorGradingTasksPresenter, used in view
    # to show circled count for each task type.
    def assignment_count
      unique_activities.count
    end

    # Public, consumed by grading_tasks/_activities_index.html.erb
    def sorted_activities
      unique_activities.sort
    end

    # Public, consumed by InstructorGradingTasks presenter to create
    # exclusions list for AlreadyGraded.
    def unique_activities
      @unique_activities ||= (@reviewable_scores.map(&:stashed_activity) - @exclusions).uniq
    end

    private def submitted_count
      @submitted_count ||= @submitted_scores.group_by(&:activity_id).transform_values(&:size)
    end

    # If there are no scores, return empty array instead of nil so
    # calls to .count or .map don't raise NoMethod for NilClass errors.
    private def scores_for_activity(activity)
      scores_by_activity[activity.id] || []
    end

    private def scores_by_activity
      @scores_by_activity ||= @reviewable_scores.group_by(&:activity_id)
    end
  end

  module TaskSetPredicates
    # Use stashed_activity name instead of just activity to avoid
    # conflicting with activity association of ScoreAction model.
    attr_accessor :stashed_activity

    # TODO: See if we should exclude credit-only from this category too.
    def upcoming_grading?
      assigned? && !due? && (pending? || partial_pending?)
    end

    def needs_grading?
      assigned? && due? && !credit_only? && (pending? || partial_pending?)
    end

    def already_graded?
      # smartbook activities are set to auto-graded. And they are already graded
      # when the partial_pending attribute exists and is false.
      assigned? && ((!pending? && instructor_graded?) || partial_pending == false)
    end

    def unassigned?
      !assigned?
    end

    def unassigned_pending?
      unassigned? && (pending? || partial_pending?)
    end
  end
end
