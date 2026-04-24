class AssignmentUpdateProcessor
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include TimeHandler

  attr_reader :activities, :params, :instructor, :focus, :success, :failure, :institution_admin_context

  def initialize(params, instructor, focus, institution_admin_context: false)
    @params = params
    @activities = prep_selected_activities
    @instructor = instructor
    @focus = focus
    @success, @failure = [], []
    @institution_admin_context = institution_admin_context
  end

  def prep_selected_activities
    activities = Activity.where(
      id: params[:selected_activities].split(',')
    ) unless params[:selected_activities].blank?
    activities = Activity.where(
      id: params[:preselected_activities].split(',')
    ) unless params[:preselected_activities].blank?
    activities.to_a.sort! do |a,b|
      # this should be lesson.rank but the publish job doesn't set the rank column
      if a.lesson.id == b.lesson.id
        a.toc_location_rank <=> b.toc_location_rank
      else
        a.lesson.id <=> b.lesson.id
      end
    end
    activities
  end
  private :prep_selected_activities

  #set custom time based after converting it into utc
  #
  #
  def update_session_due_date_and_category
    session_activity_assignment = {}
    if params[:activity_assignment]
      session_activity_assignment[:due_date] = params[:activity_assignment][:due_date] if params[:activity_assignment][:due_date]
      session_activity_assignment[:category_id] = params[:activity_assignment][:category_id] if params[:activity_assignment][:category_id]
    end
    session_activity_assignment
  end

  def flash_notice_msg
    if focus.course.is_enterprise?
      type_message = unassigning? ? 'removed' : 'added'
      "Assignments #{type_message} successfully. Sections will update shortly."
    else
      type_message = unassigning? ? 'unassigned' : 'assigned'
      "#{pluralize_without_count(success.count, 'Activity')} #{type_message} successfully."
    end
  end

  def prep_custom_due_time
    params[:activity_assignment][:custom_due_time] = set_time_from_params(params[:due_time_hour],params[:due_time_min], params[:due_time_ampm]) if params[:due_time_hour].present?
  end
  private :prep_custom_due_time

  def validate_licenses
    # Validate licenses for activities
    validator.validate
    #update with valid assignment
    @activities = validator.valid_activities
    @failure.concat(validator.invalid_activity_assignments)
  end
  private :validate_licenses

  def program
    @program ||= focus.course.program
  end
  private :program

  def process
    prep_custom_due_time
    validate_licenses
    context_params = get_assignment_context_params

    activities.each do |activity|
      activity_assignment = ActivityAssignment.new(
        activity, instructor, program, context_params
      )

      if unassigning?
        activity_assignment.unassign
        @success << activity_assignment

        if focus.course.is_enterprise? && in_institution_admin_context?
          Enterprise::UnassignActivityWorker.perform_async(
            activity.id,
            instructor.id,
            program.id,
            focus.course.id
          )
        end
      elsif activity_assignment.assign_or_update(params[:activity_assignment])
        @success << activity_assignment

        if focus.course.is_enterprise? && in_institution_admin_context?
          Enterprise::AssignActivityWorker.perform_async(
            activity.id,
            instructor.id,
            program.id,
            focus.course.id,
            activity_assignment_job_params.merge('individually_assignable' => false)
          )
        end
      else
        @failure << activity_assignment
      end
    end
  end

  private def activity_assignment_job_params
    job_params = params[:activity_assignment].to_unsafe_h.to_h

    job_params.deep_transform_values do |value|
      case value
      when 'true' then true
      when 'false' then false
      when Date, DateTime, Time then value.iso8601
      else
        value
      end
    end
  end

  def toc_location
    activities.first.toc_location
  end

  def display_rank_modal?
    return false if unassigning?
    type_validator = ActivityTypeOfContentValidator.new(activities, assigned_activities)
    type_validator.selected_activities_have_both_types? || type_validator.selected_and_assigned_activity_types_differ?
  end

  private def in_institution_admin_context?
    institution_admin_context && instructor.institution_admin?
  end

  def assigned_activities
    Activity.select('activities.*')
            .joins("INNER JOIN assignments on activities.id = assignments.assignable_id AND assignments.assignable_type = 'Activity'")
            .where(assignments: { due_date: due_date, section_id: focus.section.id })
            .where(toc_location: toc_location)
  end
  private :assigned_activities


  def get_assignment_context_params
    raise "No focus defined" unless focus.present?
    raise "No program-specific focus in session " unless focus.course.program

    # For enterprise courses: use enterprise_section only if instructor is institution_admin
    # Otherwise use the focused section
    if focus.course.is_enterprise? && focus.course.enterprise_section.present?
      if in_institution_admin_context?
        return {:section_id => focus.course.enterprise_section.id}
      else
        return {:section_id => focus.section.id} if focus.section.present?
      end
    end

    return {:section_id => focus.section.id} if focus.sections.size == 1 #need test
    return {:course_id => focus.course.id} if focus.course
    raise "No section or course in focus"
  end

  def unassigning?
    params[:update_type] == 'unassign'
  end
  private :unassigning?

  def due_date
    params[:activity_assignment][:due_date].to_date
  end
  private :due_date

  def validator
    @validator ||= AssignmentValidator.new(instructor, focus.course, activities)
  end
  private :validator

  class ActivityTypeOfContentValidator
    # Checks that there are instructor created and regular activities
    # in both selected and assigned activities arrays
    attr_reader :assigned_activities, :selected_activities

    def initialize(selected_activities, assigned_activities)
      @selected_activities = selected_activities
      @assigned_activities = assigned_activities
    end

    def selected_activities_have_both_types?
      instructor_activities_present?(:selected) && internal_activities_present?(:selected)
    end

    def selected_and_assigned_activity_types_differ?
      internal_activities_present?(:selected) && instructor_activities_present?(:assigned) ||
      instructor_activities_present?(:selected) && internal_activities_present?(:assigned)
    end

    def internal_activities_present?(type)
      activities(type).any? { |activity| !activity.instructor_created? }
    end
    private :internal_activities_present?

    def instructor_activities_present?(type)
      activities(type).any? { |activity| activity.instructor_created? }
    end
    private :instructor_activities_present?

    def activities(type)
      type == :assigned ? assigned_activities : selected_activities
    end
    private :activities
  end
end
