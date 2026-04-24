
class ActivityAssignment
  attr_reader :activity, :assignments, :section_id, :course_id, :errors, :new_assignments, :current_user, :program, :params

  def id; end

  def initialize(activity, user, program, params={})
    @activity = activity
    @program = program
    @assignments = []
    @new_assignments = []
    @errors = ActiveModel::Errors.new(self)
    params = HashWithIndifferentAccess.new(params)
    @section_id = params[:section_id]
    @course_id  = params[:course_id]
    @current_user = user
    raise "must provide either :section_id or :course_id" if @section_id.blank? && @course_id.blank?
    populate_assignments if @activity
  end

  def assign_or_update(params) #TT
    return false unless valid?(params)

    if @activity.is_a?(Resource) && @activity.protected?
      @errors.add(:base, "#{@activity.name} was not updated because it can never be shown to students")
      return false
    end
    sections.each do |section|
      assignment = assignment_for_section_id(section.id)
      cleaned_params = clean_assignment_params(assignment, section, params)
      create_or_update_assignment(assignment, cleaned_params)
    end
    CourseLibraryActivity.unhide_activity(@activity.id, course.id) if @errors.empty?
  end

  def assignment_for_section_id(section_id)
    @assignments_by_section_id ||= @assignments.inject({}) do |memo, assignment|
      memo[assignment.section_id] = assignment
      memo
    end
    @assignments_by_section_id[section_id]
  end
  private :assignment_for_section_id

  def clean_assignment_params(assignment, section, params)
      assignment_params_updater = AssignmentParamsUpdater.new(
        activity, section, assignment, program, params
      )
      assignment_params_updater.adjust_time_zone
      assignment_params_updater.set_next_rank
      assignment_params_updater.set_new_assignment_params unless assignment
      assignment_params_updater.updated_params
  end
  private :clean_assignment_params

  private def create_or_update_assignment(assignment, cleaned_params)
    filtered_params = safe_assignment_params(cleaned_params)
    new_assignment = if assignment.nil?
                       create_new_assignment(
                         filtered_params.merge(assignable: cleaned_params[:assignable])
                       )
                     else
                       Assignment.update_assignment(assignment, filtered_params)
                     end
    activity.activity_type == 'group_chat' && create_gchat_config(new_assignment, cleaned_params)
    add_new_assignment_errors(new_assignment)
  end

  private def add_new_assignment_errors(new_assignment)
    new_assignment&.errors&.full_messages&.each do |error|
      @errors.add(:base, error) unless @errors.full_messages.include?(error)
    end
  end

  private def create_new_assignment(params)
    new_assignment = Assignment.create!(params)
    new_assignment.create_assignment_set_activity if new_assignment
    new_assignment
  end

  private def create_gchat_config(new_assignment, cleaned_params)
    validated_params = cleaned_params.permit(:group_minimum, :group_maximum)
    contains_group_size_params = (['group_minimum', 'group_maximum'] - validated_params.keys).empty?
    return false unless contains_group_size_params && validate_gchat_config?(new_assignment.id, validated_params)

    GroupChatAssignmentConfig.create!(
      validated_params.merge(assignment_id: new_assignment.id)
    )
  end

  private def validate_gchat_config?(new_assignment_id, validated_params)
    test_gchat_assignment_config = GroupChatAssignmentConfig.new(
      validated_params.merge(assignment_id: new_assignment_id)
    )

    test_gchat_assignment_config.valid?
    unless test_gchat_assignment_config.errors.empty?
      @errors = test_gchat_assignment_config.errors.dup
    end
    @errors.empty?
  end

  def unassign
    @assignments.each do |assignment|
      Assignment.transaction do
        # for a timed assessment, clean up any custom student time limits
        if assignment.assessment? && assignment.time_limit.positive?
          AssessmentStudentTimeLimit.delete_time_limits(assignment.section_id,
                                                        assignment.assignable_id)
        end

        # destroy assignment set activity associated
        assignment.destroy_assignment_set_activity
        # assigned_assessement_details are removed along with the
        # assignment since they are linked with nested attributes
        assignment.destroy
      end
    end
  end

  def due_date=(date)
    if @assignments.empty?
      @assignments << Assignment.new(:due_date => date, :assignable => @activity, :section_id => find_section_id)
    end
    if @assignments.first.new_record?
      @assignments.first.due_date = date
    end
  end

  def due_date
    return nil if @assignments.empty?
    distinct_due_dates.first unless has_conflicting_due_dates?
  end

  def show_assessment
    return nil if @assignments.empty?
    distinct_show_assessment_values.first unless (distinct_show_assessment_values.size > 1)
  end

  def show_at
    return nil if @assignments.empty?
    distinct_show_at_values.first unless (distinct_show_at_values.size > 1)
  end

  def has_conflicting_due_dates?
    return false if @assignments.empty?
    (distinct_due_dates.size > 1)
  end

  def category_id=(id)
    if @assignments.empty?
      @assignments << Assignment.new(:category_id => id, :assignable => @activity, :section_id => find_section_id)
    end
    if @assignments.first.new_record?
      @assignments.first.category_id = id
    end
  end

  def category_id
    return nil if @assignments.empty?
    distinct_category_ids.first unless has_conflicting_categories?
  end

  def has_conflicting_categories?
    return false if @assignments.empty?
    (distinct_category_ids.size > 1)
  end

  def has_conflicts?
    has_conflicting_due_dates? || has_conflicting_categories?
  end

  def conflicts
    retval = []
    retval << 'due date' if has_conflicting_due_dates?
    retval << 'category' if has_conflicting_categories?
    retval.first.capitalize! unless retval.empty?
    retval
  end

  def min_date
    course.start_date
  end

  def max_date
    course.end_date
  end

  def categories
    course.categories
  end

  def course
    sections.first.course
  end

  def sections
    if @course_id.blank?
      [Section.including_enterprise.find(@section_id)]
    else
      Section.including_enterprise.by_course_by_instructor(@course_id, current_user)
    end
  end

  def valid?(params)
    validation_params = safe_assignment_params(params)
    validation_params.merge!(section: sections.first, assignable: @activity)

    test_assignment = Assignment.new(validation_params)
    test_assignment.valid?

    if validation_params[:category_id].blank?
      replace_category_errors(test_assignment, 'Please select a category.')
    elsif !Category.exists?(id: validation_params[:category_id])
      replace_category_errors(test_assignment, 'Category is no longer valid.')
    end

    unless test_assignment.errors.empty?
      @errors = test_assignment.errors.dup
    end
    @errors.empty?
  end

  private def replace_category_errors(assignment, msg)
    assignment.errors.delete(:category)
    assignment.errors.delete(:category_id)
    assignment.errors.add(:base, msg)
  end

  def all_sections
    course.sections
  end

  def assigned_sections
    activity.assignments.collect(&:section)
  end

  private

  def self.human_name
    'Assignment'
  end

  def find_section_id
    course = Course.find(@course_id) if @course_id
    section = course.sections.first if course
    section = Section.find(@section_id) if @section_id
  end

  def distinct_due_dates
    # if an assignment is assigned in one section, but not in another, store a nil due date for the section in which
    # it is not assigned, so we know that not all sections have the same setting
    due_dates = []
    sections.each do |section|
      assignment_for_section = @assignments.detect { |assignment| assignment.section == section }
      due_dates << (assignment_for_section ? assignment_for_section.due_date : nil)
    end
    due_dates.uniq
  end

  def distinct_show_assessment_values
    show_assessment_values = []
    sections.each do |section|
      assignment_for_section = @assignments.detect {|assignment| assignment.section == section}
      show_assessment_values << (assignment_for_section ? assignment_for_section.show_assessment : nil)
    end
    show_assessment_values.uniq
  end

  def distinct_show_at_values
    show_at_values = []
    sections.each do |section|
      assignment_for_section = @assignments.detect {|assignment| assignment.section == section}
      show_at_values << (assignment_for_section ? assignment_for_section.show_at : nil)
    end
    show_at_values.uniq
  end

  def distinct_category_ids
    # if an assignment is assigned in one section, but not in another, store a nil category_id for the section in which
    # it is not assigned, so we know that not all sections have the same setting
    category_ids = []
    sections.each do |section|
      assignment_for_section = @assignments.detect {|assignment| assignment.section == section}
      category_ids << (assignment_for_section ? assignment_for_section.category_id : nil)
    end
    category_ids.uniq
  end

  def populate_assignments
    @assignments = Assignment.activity_assignments(sections, [@activity]) unless @activity.new_record?
  end

  private def safe_assignment_params(params)
    if params.class != ActionController::Parameters
      params = ActionController::Parameters.new(params)
    end
    params.permit(
      :answer_availability, :answers_available_at, :assignable_id,
      :assignable_type, :category_id, :current, :custom_due_time, :due_date,
      :grade_availability, :grades_available_at, :group,
      :individually_assignable,
      :randomize_per_student, :rank, :section_id, :show_assessment, :show_at,
      :study_schedule_id, :assigned_assessment_detail_id,
      :vol_program,
      assigned_assessment_detail_attributes: [
        :number_of_attempts, :password, :time_limit
      ]
    )
  end

  class AssignmentParamsUpdater
    attr_reader :activity, :section, :assignment, :program, :params, :updated_params

    def initialize(activity, section, assignment, program, params)
      @section = section
      @activity = activity
      @assignment = assignment
      @program = program
      @params = params
      @updated_params = params.deep_dup
    end

    def set_next_rank
      return unless activity.is_a?(Activity)

      updated_params[:rank] = Assignment.next_rank(section, params[:due_date], activity)
    end

    def adjust_time_zone
      %i[show_at grades_available_at answers_available_at].each do |field|
        if updated_params[field].present?
          @updated_params[field] = Time.use_zone(section.time_zone) do
            Time.zone.parse(updated_params[field])
          end
        end
      end
    end

    def set_new_assignment_params
      unless assignment
        updated_params[:assignable] = activity
        updated_params[:section_id] = section.id
      end
    end
  end
end
