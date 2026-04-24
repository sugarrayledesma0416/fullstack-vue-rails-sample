class Instructor::CoursesController < RequireInstructorController
  before_action :redirect_to_local_url,
                if: -> { params[:guids].present? && params[:guids] },
                only: :new

  include HasHelp
  include Policy::Course::ControllerMethods
  skip_before_action :set_current_focus,
                     :assign_course_sections_and_students_from_focus
  before_action :contextual_help_url, only: %i[new edit update]
  before_action :set_current_program
  before_action :set_current_focus, only: :edit
  before_action :assign_course, only: %i[content_step destroy edit update]
  before_action :require_course_owner, only: %i[content_step destroy edit update]
  before_action :require_course_policy_permission, only: %i[new content_step create edit update]

  # Since these endpoints render HTML and then call themselves to render JSON,
  # the browser caches the JSON, and incorrectly displays it when the user
  # hits back/forward.
  before_action :set_cache_buster, only: %i[new edit]
  before_action :assign_new_course_school, only: %i[create update]
  before_action :assign_return_to_link, only: %i[new edit update]
  before_action :assign_school, only: :new
  before_action :assign_school_from_course, only: :edit

  def show
    respond_to do |format|
      format.html { head :forbidden }
      format.js do
        render(
          partial: 'instructor/courses/course_hover',
          locals: { course: Course.find(params[:id]) }
        )
      end
    end
  end

  def new
    course = Course.new(new_course_params)
    # This view has a dynamic h1 header, so the normal @page_title
    # variable needs to be unset so the layout doesn't render an
    # extra h1. The h1 will be set by a Vue app.
    @page_title = nil

    respond_to do |format|
      format.html do
        render layout: 'music_v1/default'
      end
      format.json do
        render json: CourseOptions.new(
          current_user, course, current_program, selected_school_id
        ), serializer: CourseOptionsSerializer
      end
    end
  end

  private def new_course_params
    Course.default_values.merge(
      program_id: current_program.id,
      school_id: params[:school_id].to_i,
      first_unit_id: current_program.units.first.id,
      last_unit_id: current_program.units.last.id
    )
  end

  private def express_course_params
    # assignments and categories are generated without user input
    # so can be considered safe. The hash keys are also unpredictable.
    # Apply a blanket .permit! if the param key exists, otherwise set to an
    # empty hash.
    safe_params = %i[assignments categories].each_with_object({}) do |key, memo|
      # If there's no param for the specified key, set to an empty hash.
      memo[key] = params[key]&.permit! || {}
    end

    params.permit(
      :copy_igc,
      :src_section_id,
      sections: [],
      course_package_ids: [],
      course: [
        :allows_help_requests,
        :allows_review_requests,
        :allow_audio_transcripts,
        :allow_video_popup_translation,
        :allow_individual_assign,
        :chat_level,
        :course_library_from,
        :copy_shared_activities_from_previous_course,
        :copy_created_activities_from_previous_course,
        :enable_vocab_tutorial_translations,
        :end_date,
        :first_unit_id,
        :is_template,
        :last_unit_id,
        :level,
        :name,
        :school_id,
        :selected_learning_track,
        :share_to_google_classroom,
        :show_estimated_times,
        :start_date,
        :video_subtitle_languages,
        :video_transcript_languages,
        standard_set_ids: [],
        categories_attributes:
        [
          :accept_late_work,
          :credit_only,
          :course_id,
          :current_scoring_ruleset_id,
          :drop_low_scores,
          :enhanced_feedback_disabled,
          :id,
          :late_work_penalty,
          :max_attempts,
          :name,
          :penalty_percent,
          :rank,
          :weighting_percent,
          :_destroy,
          scoring_rulesets_attributes:
          %i[
            category_id
            id
            ignore_accents
            ignore_capitalization
            ignore_punctuation
            _destroy
          ]
        ],
        course_package_ids: []
      ]
    ).merge(safe_params)
  end

  private def course_params
    params.require(:course).permit(
      :ai_virtual_chat_level,
      :allows_help_requests,
      :allows_review_requests,
      :allow_audio_transcripts,
      :allow_video_popup_translation,
      :allow_individual_assign,
      :chat_level,
      :course_library_from,
      :copy_shared_activities_from_previous_course,
      :copy_created_activities_from_previous_course,
      :enable_vocab_tutorial_translations,
      :end_date,
      :first_unit_id,
      :is_template,
      :last_unit_id,
      :level,
      :name,
      :school_id,
      :share_to_google_classroom,
      :share_to_portfolio,
      :show_estimated_times,
      :start_date,
      :video_subtitle_languages,
      :video_transcript_languages,
      portfolio_activity_types: {},
      course_package_ids: [],
      categories_attributes: [
        :accept_late_work,
        :credit_only,
        :course_id,
        :current_scoring_ruleset_id,
        :drop_low_scores,
        :enhanced_feedback_disabled,
        :id,
        :late_work_penalty,
        :max_attempts,
        :name,
        :penalty_percent,
        :rank,
        :weighting_percent,
        :_destroy,
        scoring_rulesets_attributes: [
          :category_id,
          :id,
          :ignore_accents,
          :ignore_capitalization,
          :ignore_punctuation,
          :_destroy
        ]
      ],
      standard_set_ids: []
    ).tap do |memo|
      memo[:chat_level] = 'disabled' if @new_course_school.has_chat_support_disabled?
    end
  end

  def create
    fxn = lambda do
      course = Course.new(course_params.merge(course_creation_extra_params))
      course.validate_categories = true
      course.save
      course
    end

    with_error_handling(fxn) do |course|
      course_package_ids = params[:course][:course_package_ids]
      CourseLicenseCreatorWorker.perform_in(
        3.seconds,
        course.guid,
        course_package_ids
      )
      flash[:notice] = "Course <b>#{course.name}</b> was created successfully."
      set_focus_after_creation(course)
      render status: :created, json: course
    end
  end

  private def which_streamlined_rostering_setup(one_roster_linked:, lti_roster_linked:)
    if one_roster_linked
      'RA'
    elsif lti_roster_linked
      'LTI-A-R'
    else
      ''
    end
  end

  def express_create
    # Don't mind the man behind the curtain.
    if params[:course][:categories_attributes].nil?
      params[:course][:categories_attributes] = []
    end

    creator = ExpressCourseCreator.new(current_user, current_program, express_course_params)
    course = creator.create
    flash[:notice] = "Course <b>#{course.name}</b> was created successfully."
    set_focus_after_creation(course)
    render json: { course_id: course.id,
                   job_id: creator.job_id }
  end

  def edit
    respond_to do |format|
      format.html do
        render layout: 'music_v1/default'
      end
      format.json do
        render json: CourseOptions.new(
          current_user, @course, current_program, selected_school_id
        ), serializer: CourseOptionsSerializer
      end
    end
  end

  def update
    # If the parameter is not present, consider it is an empty array.
    if params[:course] && params[:course][:standard_set_ids].nil?
      params[:course][:standard_set_ids] = []
    end

    fxn = lambda do
      update_params = course_params.merge(course_update_extra_params)
      course_old_name = @course.name
      @course = course_update(@course, update_params)

      if @course.course_share_to_portfolio? &&
         course_old_name != update_params['name'] &&
         @course.sections.present?
        Portfolio::UpdateBulkGroupsWorker.perform_async(@course.id)
      end

      @course
    end

    with_error_handling(fxn) do
      course_package_ids = course_params[:course_package_ids]
      CourseLicenseCreatorWorker.perform_in(
        3.seconds,
        @course.guid,
        course_package_ids
      )
      render status: :ok, json: @course.reload, serializer: CourseSerializer
    end
  end

  def destroy
    @course.archive
    if @course.errors.empty?
      flash[:notice] = "Course <b>#{@course.name}</b> was deleted successfully."
    else
      flash[:error] = @course.errors.full_messages.join('<br />')
    end

    # For course templates, we make an AJAX request to this action as an endpoint
    # and need a JSON response.
    #
    # For regular courses, we navigate to this action and redirect afterward.
    if @course.is_template?
      render json: { status: :ok }
    else
      redirect_to instructor_dashboard_path(program_id: @course.program_id)
    end
  end

  def show_summary_pdf
    respond_to do |format|
      format.pdf do
        course_data_params = JSON.parse(
          URI.decode_www_form_component(params[:course_data])
        )
        @course = Course.new(course_data_params['course']&.except('selected_learning_track',
                                                                  'one_roster_linked',
                                                                  'lti_roster_linked',
                                                                  'display_on_dashboard'))
        @course_packages_names = JSON.parse(
          URI.decode_www_form_component(params[:course_packages_names])
        )
        render pdf: "course_summary_#{Time.new.strftime('%Y-%m-%d')}",
               template: 'instructor/courses/_course_summary',
               disposition: 'attachment',
               layout: 'pdf.html'
      end
    end
  end

  def content_step
    respond_to do |format|
      format.json do
        render json: {
          course_has_individual_assignments: @course.has_individual_assignments?
        }
      end
    end
  end

  def assign_course
    @course = Course.find(params[:id])
  end
  private :assign_course

  private def course_update(course, update_params)
    course.update(update_params)

    course
  end

  private def course_update_extra_params
    { program_id: params[:program_id] }
  end

  private def course_creation_extra_params
    {
      course_config_json: {
        setup_method: 'custom_setup',
        supersite_jr: current_program.supersite_junior?,
        express_course_copied: '',
        course_copied_id: '',
        learning_track: '',
        streamlined_rostering_setup: which_streamlined_rostering_setup(
          one_roster_linked: params['course']['one_roster_linked'],
          lti_roster_linked: params['course']['lti_roster_linked']
        )
      }.to_json,
      owner_id: current_user.id,
      program_id: params[:program_id]
    }.merge(help_request_extra_params)
  end

  private def help_request_extra_params
    if supersite_junior?
      {
        'allows_help_requests' => false,
        'allows_review_requests' => false
      }
    else
      {}
    end
  end

  private def redirect_unless_course_owner
    redirect_to_instructor_dashboard unless @course.owned_by?(current_user)
  end

  # Accepts an lambda to execute that returns a course object.
  #
  # Evaluate block when course has no errors, otherwise respond with
  # full messages as JSON and status code 422.
  def with_error_handling(course_proc)
    course = course_proc.call

    if course.all_error_messages.empty?
      yield course
    else
      render status: :unprocessable_entity, json: { errors: course.all_error_messages }
    end
  rescue StandardError => e
    # This is typically going to be due to the categories attributes being
    # an empty string.
    if e.message =~ /Hash or Array expected, got/
      render(
        json: { 'courses' => ['Course must have at least one category.'] },
        status: :unprocessable_entity
      )
    else
      render(
        json: { 'courses' => ["We're sorry, your course could not be saved."] },
        status: :internal_server_error
      )
      VHLMonitor.notify(e)
    end
  end
  private :with_error_handling

  private def redirect_to_local_url
    school_id = School.by_guid(params[:school_id]).id

    redirect_to instructor_new_course_url(program_id: params[:program_id], school_id: school_id)
  end

  COURSE_OWNER_REQUIRED_MESSAGE = 'You must be the owner of this course ' \
                                  'to make changes.'.freeze

  private def require_course_owner
    return if current_user == @course.owner

    respond_to do |format|
      format.json do
        render plain: COURSE_OWNER_REQUIRED_MESSAGE, status: :forbidden
      end
      format.html do
        flash[:error] = COURSE_OWNER_REQUIRED_MESSAGE
        redirect_to instructor_dashboard_path(program_id: current_program.id)
      end
    end
  end

  private def school_id_from_course_params
    return @school_id_from_course_params if defined? @school_id_from_course_params

    @school_id_from_course_params = params.require(:course).permit(:school_id)[:school_id]
  end

  private def selected_school_id
    case params[:action].to_sym
    when :new then params[:selected_school_id] || params[:school_id]
    when :create, :update then school_id_from_course_params
    when :edit, :content_step then params[:selected_school_id] || @course.school_id
    else
      raise "No selected_school_id defined for #{params[:action]}"
    end
  end

  private def assign_return_to_link
    @return_label = 'Return to Dashboard'
    @return_url = instructor_dashboard_path(current_program.id)
  end

  private def assign_school
    @school = School.find(params[:school_id]) if params[:school_id].present?
  end

  private def assign_school_from_course
    @school = School.find(@course.school_id) if @course.present?
  end

  # Assigns the new course's school. If the school_id parameter is present,
  # use it to find the school, otherwise, it means the school did not change, so
  # we use the current one.
  private def assign_new_course_school
    id = school_id_from_course_params.presence || @course.school_id
    @new_course_school = School.find(id)
  end
end
