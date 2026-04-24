class HelpRequestSubmitter
  attr_accessor :user, :formatted_params, :activity_params, :help_request, :result, :status

  def initialize(user, params, request_env)
    self.user = user
    self.formatted_params = filter_params(params, request_env)
    self.status = :unprocessable_entity
    self.activity_params = Rack::Utils.parse_query(params[:activity_form_contents])
    @request_env = request_env
  end

  def submit
    # Before creating the help request, we make sure all the parameters are
    # correct. If this is not the case, it's more likely that the user edited
    # the POST request parameters. In this case, we just return a generic error
    # message to not leak any information.
    unless valid_parameters?
      self.result = { errors: ['Error submitting the help request.'] }
      return self
    end

    create_help_request
    set_result_and_status
    if status == :ok
      Notifier.problem_report(help_request).deliver_now if help_request.problem_report?
      save_activity_work if should_save_activity_work?
    end
    self
  end

  private def valid_parameters?
    if section&.section_zero?
      # When submitting from section zero, ensure the activity exists
      activity
    elsif user.instructor?
      # When an instructor submits, ensure the section exists and the instructor
      # is an instructor in the specified section
      section &&
      SectionInstructor.exists?(user_id: user.id, section_id: section.id) &&
      activity
    else
      # When a student submits, ensure he's enrolled in the specified section,
      # that the course is open and allows help requests
      Enrollment.by_section(section).by_student(user).exists? &&
      course.open? &&
      request_type_allowed? &&
      activity
    end
  end

  private def request_type_allowed?
    request_type = formatted_params[:request_type]

    case request_type
    when 'request_help'
      course.allows_help_requests?
    when 'request_review'
      course.allows_review_requests?
    else
      true
    end
  end

  private def section
    return @section if defined? @section

    @section = if formatted_params[:section_id].to_s == '0'
                 Section.section_zero
               else
                 # Use find_by to not raise an error when the section does not exist.
                 Section.find_by(id: formatted_params[:section_id])
               end
  end

  private def course
    section.course
  end

  private def has_responses_to_save?
    # We check if any of question fields was responded
    submitted_response_keys.any? { |key| activity_params[key].present? }
  end

  private def submitted_response_keys
    # activity_params could include another fields serialized from activity,
    # so we need to get the response fields from the activity (e.g question_01, question_1_wol_1)
    # we compare result labels and activity_params key to retrieve an array of possible responded fields
    # from the activity
    attempt.activity.result_labels & activity_params.keys
  end

  private def save_activity_work
    ActivityWorkSaver.new(activity, attempt, activity_params, @request_env).save
  end

  private def should_save_activity_work?
    if user.instructor?
      false
    else
      !attempt.completed? && savable_view_type? && savable_activity_type? && has_responses_to_save?
    end
  end

  private def savable_view_type?
    %i[complete decide].exclude?(attempt.current_view)
  end

  private def savable_activity_type?
    attempt.has_submittable_activity? && !(
      attempt.virtual_chat? ||
      attempt.partner_chat? ||
      attempt.solo_video_recording? ||
      attempt.group_chat?
    )
  end

  private def activity
    # Be sure the specified activity exists and belongs to the course's program
    @activity ||= Activity.where(
      id: formatted_params[:activity_id],
      cms_activity_id: formatted_params[:cms_activity_id],
      cms_revision_id: formatted_params[:cms_revision_id]
    ).joins(
      [lesson: :unit]
    ).where(
      units: { program_id: }
    ).first
  end

  private def program_id
    if user.instructor? || section.section_zero?
      formatted_params[:program_id]
    else
      course.program_id
    end
  end

  private def attempt
    @attempt ||= Attempt.find_or_new(user, activity, formatted_params[:section_id])
  end

  private def set_result_and_status
    if help_request.errors.any?
      self.result = { errors: help_request.errors.full_messages }
    else
      self.result = help_request.attributes
      self.status = :ok
    end
  end

  private def create_help_request
    self.help_request = HelpRequest.create(help_request_attrs)
  end

  private def help_request_attrs
    formatted_params.merge(
      program_id:,
      user_id: user.id
    )
  end

  private def filter_params(params, request_env)
    agent = UserAgent.parse(request_env['HTTP_USER_AGENT'])
    params.except(:activity_form_contents).merge(
      ip_address: request_env['REMOTE_ADDR'],
      user_agent_string: request_env['HTTP_USER_AGENT'],
      browser_name: agent.browser,
      browser_version: agent.version.to_s,
      operating_system: agent.os
    )
  end
end
