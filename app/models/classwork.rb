class Classwork
  include IndividualAssignmentQueryable

  attr_reader :section, :section_id, :user, :course, :instructor
  attr_accessor :disable_enhanced_feedback

  def initialize(user, section = '0')
    @user = user
    if section.class == Section
      @section = section
    else
      @section = Section.find_by_id(section)
    end

    @section_id = 0

    if @section
      @course = @section.course
      @instructor = @section.instructor
      @section_id = @section.id
    end
  end

  def user_id
    user.id
  end

  def closed_section?
    @section && @section.closed?
  end

  def units_covered
    return @units_covered if @units_covered
    @units_covered = @section.course.units_covered
  end

  def completed_count(activity_type, lesson_id)
    raise "invalid completed activity type '#{activity_type}'" unless :assigned == activity_type
    unless @completed_count
      @completed_count = Hash.new

      all_completed      = Attempt.all_submitted_and_completed_activities(@user, @section.id)

      assigned_completed = select_assigned_activities(all_completed)

      units_covered.each do |lesson|
        @completed_count[lesson.id] = {
          :assigned => assigned_completed.count{|activity|activity.lesson_id == lesson.id}
        }
      end
    end
    @completed_count[lesson_id][activity_type]
  end

  def all_assignments_for_date(due_date, concept = nil, category = nil)
    scope = Assignment.by_type(Activity).where(section_id: @section).where(
      [
        'COALESCE(individual_assignments.due_date, assignments.due_date) = ?',
        due_date
      ]
    )

    scope = apply_individual_assignment_filter(scope, @user.id)
    scope = apply_assignment_set_scope(scope)
    scope = scope.where(activities: { concept_id: concept.id }) if concept
    scope = scope.where(category_id: category.id) if category
    scope.preload(assignable: :concept)
         .sort_by(&:rank)
  end

  def apply_assignment_set_scope(scope)
    scope.select(ClassworkFilter::ASSIGNMENT_SELECT_STATEMENT).joins(
      AssignmentSorter::ASSIGNMENT_JOINS
    ).order(
      Arel.sql(AssignmentSorter::ASSIGNMENT_ORDER)
    )
  end

  def select_completed_activities(activities)
    Attempt.completed_activity_ids(@user, @section, activities)
  end

  def select_assigned_activities(activities)
    Assignment.activity_assignments(@section, activities).collect{|assignment| assignment.assignable}
  end

  def new_workset(activity_ids)
    return nil unless @section
    Workset.create_or_update(@user, @section, activity_ids.join(','))
  end

  def current_workset(activity = nil)
    Workset.current(@user, @section, activity) if activity && assignment(activity)
  end

  def find_or_new_attempt(activity)
    @attempt = Attempt.find_or_new(@user, activity, section_id)
    unless @attempt.scoring_ruleset
      activity = @attempt.activity if !activity.is_a? Activity
      current_assignment = assignment(activity)
      @attempt.scoring_ruleset = current_scoring_ruleset(current_assignment)
    end
    @attempt.disable_enhanced_feedback = disable_enhanced_feedback?(assignment(activity)) if @attempt.is_a? Attempt
    @attempt
  end

  def find_active_attempt(activity)
    @attempt = Attempt.active_attempt(@user, section_id, activity)
    @attempt.disable_enhanced_feedback = disable_enhanced_feedback?(assignment(activity)) if @attempt.is_a? Attempt
    @attempt
  end

  def practice_attempt(activity)
    @attempt = Attempt.practice_attempt(@user, section_id, activity)
    @attempt.disable_enhanced_feedback = disable_enhanced_feedback?(assignment(activity)) if @attempt.is_a? Attempt
    @attempt
  end

  def ensure_completed_attempt(activity)
    if @section
      Attempt.create_completed(@user, activity, @section) if incomplete?(activity)
    end
  end

  def incomplete?(activity)
    select_completed_activities([activity]).empty?
  end

  def overdue?(activity)
    assignment = assignment(activity)
    return false unless assignment
    assignment.late?(Time.zone.now) && incomplete?(activity)
  end

  def assignment(activity)
    return unless @section

    scope = Assignment.where(section_id: @section,
                             assignable_id: activity.id,
                             assignable_type: activity.class.to_s)
    assignment = apply_individual_assignment_filter(scope, @user.id).first

    # Prevent looking up the activity again when assignable is accessed.
    assignment.assignable = activity if assignment
    assignment
  end

  def current_scoring_ruleset(assignment)
    scoring_ruleset = ScoringRuleset.default

    if assignment
      scoring_ruleset = assignment.category.current_scoring_ruleset
    end

    scoring_ruleset
  end

  def disable_enhanced_feedback?(assignment)
    assignment && assignment.disable_enhanced_feedback?
  end
end
