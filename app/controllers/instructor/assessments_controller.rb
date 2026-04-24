class Instructor::AssessmentsController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  include HasHelp
  include ReturnLink
  include Instructor::CreatedActivityLinkParams
  include LessonNavigable

  before_action :ensure_component_access
  before_action :assign_menu_coords
  before_action :contextual_help_url, only: :index
  before_action :hide_header, only: %i[new]
  before_action :remove_script_tags, only: %i[create update]
  before_action :prevent_unauthorized_creating, only: :create

  skip_before_action :set_current_program, only: :update_assessment
  skip_before_action :set_current_focus, only: :update_assessment
  skip_before_action :assign_course_sections_and_students_from_focus,
                     only: :update_assessment

  NOT_AUTHORIZED_TO_CREATE_MESSAGE = 'You are not authorized to create assessments ' \
                                     'in this course.'.freeze

  # Hide program logo
  def hide_header
    @hide_header = true
  end

  def index
    @page_title = 'Assessments'
    assessments_toc_navigation_data = load_assessments_toc_navigation_data.with_indifferent_access
    @presenter = InstructorAssessmentTocPresenter.new(
      current_program,
      current_focus,
      current_user,
      assessments_toc_navigation_data.merge(
        params.permit(
          :all_units,
          :display_lesson,
          :program_id,
          :section_id,
          :start_strand,
          :start_topic,
          :start_unit,
          :toc_location
        )
      ),
      session
    )
    set_return_info('Return to Assessment') do
      instructor_assessments_path(current_program, path_options)
    end
    if params.keys.include?('display_lesson')
      update_toc_lesson_navigation(
        assessments_toc_data: params.slice(:display_lesson, :toc_location, :start_unit)
      )
    end
    @path_options = (path_options.presence || assessments_toc_navigation_data)
    render 'show'
  end

  def new
    @return_url = request.referer if request.referer
    @assessment = InstructorCreatedActivity.new(new_assessment_attrs)
    render :new, :layout => 'layouts/activity'
  end

  def create
    @assessment = InstructorCreatedActivity.new(create_assessment_attrs)
    @assessment.student_title = nil if create_assessment_attrs[:student_title].blank?
    if @assessment.save
      flash[:notice] = "Assessment #{@assessment.title} successfully created."
      if params[:instructor_created_activity][:save_action] == 'exit'
        redirect_to instructor_assessments_path(current_program,
                                                display_lesson: @assessment.lesson.id,
                                                toc_location: @assessment.toc_location)
      else
        redirect_to edit_instructor_created_activity_path(
                      instructor_created_activity_link_params(@assessment)
                    )
      end
    else
      flash.now[:error] = 'Assessment not saved.'
      @classwork = Classwork.new(current_user, current_section_id)
      render :new
    end
  end

  def update_assessment
    @assignments = params[:assignments].split('-')
    @update_type = params[:update_type]
    Assignment.transaction do
      @assignments.each do |assignment_id|
        assignment = Assignment.find_by_id(assignment_id)
        assignment.update_availability @update_type
        assignment.save!
      end
    end
    @activity_id = params[:activity]
    head :ok
  end

  private def lesson
    @lesson ||= Lesson.find(lesson_id)
  end

  private def lesson_id
    params[:override_lesson_id].presence || params[:lesson_id]
  end

  private def toc_entry_id
    params[:override_toc_entry_id].presence || params[:toc_entry_id]
  end

  private def concept_id
    lesson.strand_for_toc_location(toc_entry_id).location
  end

  private def new_assessment_attrs
    {
      content_json: {
        activities: [],
        activity_type: 'exam',
        external_references: [],
        inline_external_references: [],
        language: current_program.language_code,
        media_items: [],
        question_count: 0
      }.to_json,
      title: 'New assessment'
    }.merge(assessment_attrs)
  end

  private def create_assessment_attrs
    safe_create_assessment_params.merge(assessment_attrs)
  end

  private def assessment_attrs
    {
      activity_type: 'exam',
      concept_id: concept_id,
      instructor_id: current_user.id,
      language_code: current_program.language_code,
      lesson_id: lesson.id,
      process_as_assessment: true,
      toc_location: toc_entry_id
    }
  end

  private def safe_create_assessment_params
    params.require(:instructor_created_activity).permit(
      :assignment_group,
      :content_json,
      :draft,
      :student_title,
      :title
    )
  end

  private def remove_script_tags
    %i[title student_title].each do |act_attr|
      params[act_attr] = script_tag_sanitizer(params[act_attr]) unless params[act_attr].nil?
    end
  end

  private def assign_menu_coords
    @menu_location = 'content'
  end

  private def ensure_component_access
    program_settings = ProgramSettings.new(current_program)

    unless program_settings.has_assessment?
      flash[:notice] = 'This Supersite does not have Assessment content.'
      redirect_to instructor_dashboard_path(current_program)
    end
  end

  private def prevent_unauthorized_creating
    return if allowed_to_create_content?

    flash[:error] = NOT_AUTHORIZED_TO_CREATE_MESSAGE
    redirect_to_best_default_path
  end

  private def allowed_to_create_content?
    # TODO: this guard clause needs to be removed when we undo the dark launch checks
    return true unless Rails.application.config.enable_gradebook_dev_features || cookies[:dev]

    Policy::Course::CreateEdit.new(current_user)
                              .allowed_to_create_content_in_course?(
                                current_focus.course
                              )
  end
end
