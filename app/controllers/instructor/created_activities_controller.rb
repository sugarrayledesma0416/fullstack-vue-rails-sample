class Instructor::CreatedActivitiesController < RequireInstructorController
  helper MaestroActivityEngine::ActivitiesHelper

  include PopupRequestable
  include ReturnLink
  include Instructor::CreatedActivityLinkParams
  include Uploadable::Controller
  include LessonNavigable
  include SharedContent::RedirectionLinkHelper

  NOT_AUTHORIZED_MESSAGE = 'You are not authorized to view that activity.'.freeze
  NOT_AUTHORIZED_TO_CREATE_MESSAGE = 'You are not authorized to create activities ' \
                                     'in this course.'.freeze
  CONTENT_SHARING_DISABLED_MESSAGE = 'Your school has disabled instructor content sharing.'.freeze

  before_action :assign_instructor_content_presenter,
                only: %i[index confirm_copy_previous_edition_igcs copy_previous_edition_igcs]
  before_action :assign_instructor_shared_presenter, only: %i[shared_content_index]
  before_action :assign_activity_type, only: %i[new update create]
  before_action :assign_activity_params, only: %i[update create]
  before_action :assign_created_activity, only: %i[
    confirm_destroy
    convert_to_shared
    copy_to_mycontent
    destroy
    edit
    remove_as_shared
    set_activity_private
    show
    share_activity
    update
  ]
  # prevent_unauthorized_editing must happen after :assign_created_activity
  # so that the activity's instructor id is not set to the current user, which
  # would allow a non-author to make edits.
  before_action :prevent_unauthorized_editing, only: %i[
    confirm_destroy
    destroy
    edit
    set_activity_private
    share_activity
    update
  ]
  before_action :assign_activity_list_header, only: %i[new create edit update]
  before_action :assign_is_assessment_tab, only: %i[new edit]
  before_action :hide_header, except: %i[index shared_content_index]
  before_action :assign_return_link
  before_action :assign_from_my_content
  before_action :assign_menu_coords, only: %i[
    confirm_destroy
    destroy
    index
    shared_content_index
  ]
  before_action :remove_script_tags, only: %i[create update]
  before_action :prevent_unauthorized_creating, only: :create
  before_action :set_page,
                only: %i[confirm_destroy destroy edit update shared_content_index copy_to_mycontent]
  before_action :prevent_content_sharing_access,
                only: %i[shared_content_index share_activity set_activity_private]

  # Hide program logo
  def hide_header
    @hide_header = true
  end

  def index
    set_return_info('Return to My Content') do
      instructor_mycontent_path(current_program)
    end

    @path_options = path_options if path_options
  end

  private def assign_instructor_content_presenter
    activities_toc_navigation_data = load_activities_toc_navigation_data.with_indifferent_access
    req_params = activities_toc_navigation_data.merge(params.to_unsafe_h)
    @presenter = InstructorContentPresenter.new(current_program,
                                                current_user,
                                                current_focus,
                                                req_params,
                                                session[:saved_location])
    @presenter.extend(MyContentPresentable)

    if @presenter.has_uncopied_igcs_from_previous_edition?
      flash.now[:warning] = @presenter.uncopied_igcs_from_previous_edition_message
    end

    @alternative_content_info = {
      url_shared_content: instructor_shared_content_path(@presenter.program),
      show_copy_to_mycontent: @presenter.uncopied_igc?,
      content_partial: 'content',
      content: 'my_content',
      has_filters: build_filters.values.any?(&:present?)
    }
    @my_content_params = assing_filtered_params
    @instructor_activities = @presenter.lesson_activities(build_filters)
  end

  def create_from_assessment
    processor = copy_assessment

    flash[processor.message_type] = processor.messages
    redirect_to_assessment_or_content_toc(processor.created_activity)
  end

  def create_from_activity
    processor = copy_activity

    if processor.valid?
      redirect_to_assessment_or_content_toc(processor.created_activity)
    else
      redirect_back(fallback_location: instructor_mycontent_path(
        params[:program_id], display_lesson: params['display_lesson']
      ))
    end
    flash[processor.message_type] = processor.messages
  end

  private def copy_activity
    ActivityCopier.new(params[:id], current_user.id, current_focus.course&.id).tap do |copier|
      copier.created_activity.draft = true
      copier.copy
    end
  end

  private def copy_assessment
    AssessmentCopier.new(params[:id], current_user.id).tap do |copier|
      copier.created_activity.draft = true
      copier.copy
    end
  end

  def new
    @created_activity = InstructorCreatedActivity.new
    render :new, :layout => layout
  end

  def create
    @activity_params[:student_title] = nil if @activity_params[:student_title].blank?

    @created_activity = InstructorCreatedActivity.new(@activity_params)

    if @created_activity.save
      flash.notice = "Activity #{@created_activity.title} has been created."
      redirect_to_assessment_or_content_toc(@created_activity)
    else
      render :new, :layout => 'layouts/activity'
    end
  end

  def edit
    @return_url = request.referer if request.referer
    if request_from_popup?
      @return_label = 'Cancel'
      @return_url = path_to_section_activity(current_section)
    end

    @activity = @created_activity
    @activity_type = @created_activity.activity_type
    @classwork = Classwork.new(current_user, current_section_id)
    if ['exam', 'diagnostic'].include?(@activity_type)
      render 'assessment_edit', layout: layout
    elsif @activity.has_rubric?
      assign_activity_preview_prerequisites
      render :edit_rubric, layout: layout
    else
      render :edit, layout: layout
    end
  end

  def update
    @activity_params[:student_title] = nil if @activity_params[:student_title].blank?

    # Custom logic for rubric xml
    if @activity_params[:rubric_json]
      rubric_json = @activity_params.delete(:rubric_json)
      new_doc = RubricUpdater.new(
        @created_activity.content, rubric_json
      ).new_doc
      @activity_params[:generated_content] = new_doc.to_xml
      current_record = @created_activity.custom_rubrics.last
      @created_activity.custom_rubrics << current_record.dup.tap do |memo|
        memo.activity_revision_id = nil
        memo.stored_rubric = new_doc.at('rubric').to_xml
      end
    end

    if @created_activity.update(@activity_params)
      flash.notice = "Activity #{@created_activity.title} has been updated."
      if request_from_popup?
        redirect_to path_to_section_activity(current_section)
      elsif params[:instructor_created_activity][:hide_from_my_content]
        flash.notice = "Activity #{@created_activity.title} has been deleted."
        redirect_to instructor_mycontent_url(current_program, toc_location_params(@created_activity.lesson, @created_activity.toc_location))
      else
        redirect_to_assessment_or_content_toc(@created_activity, page: @page.to_i)
      end
    else
      flash.now[:error] = @created_activity.errors.full_messages.join(', ')
      if ['exam', 'diagnostic'].include?(@created_activity.activity_type)
        render 'assessment_edit', layout: layout
      else
        render :edit, layout: layout
      end
    end
  end

  def shared_content_index
    set_return_info('Return to Shared Activities') do
      instructor_shared_content_path(current_program)
    end

    @path_options = path_options if path_options
    render :index
  end

  private def assign_instructor_shared_presenter
    @presenter = SharedContentPresenter.new(current_program,
                                            current_user,
                                            current_focus,
                                            params.to_unsafe_h,
                                            session[:saved_location])
    @alternative_content_info = {
      url_mycontent: instructor_mycontent_path(@presenter.program),
      show_copy_to_mycontent: false,
      content_partial: 'content',
      content: 'shared_content',
      has_filters: build_filters.values.any?(&:present?)
    }

    @my_content_params = assing_filtered_params

    @instructor_activities = @presenter.lesson_activities(build_filters)
  end

  private def build_filters
    @build_filters ||= {
      lesson_ids: params[:selected_lesson_ids].try(:split, ','),
      strands: params[:selected_strands].try(:split, ','),
      types: params[:selected_types].try(:split, ','),
      shared_activity_creator_ids: params[:selected_shared_activity_creator_ids].try(:split, ',')
    }
  end

  def convert_to_shared
    SharedLibraryActivity.create!(source_activity_id: @created_activity.id,
                                school_id: current_focus.course.school.id)

    flash[:notice] = "#{@created_activity.title} has successfully been requested to share with #{current_focus.course.school.name}".html_safe

    redirect_to instructor_mycontent_path(params[:program_id],
                                          display_lesson: params['display_lesson'])
  end

  def share_activity
    begin
      ActiveRecord::Base.transaction do
        current_user.schools.each do |school|
          SharedLibraryActivity.create!(source_activity_id: @created_activity.id,
                                        school_id: school.id,
                                        is_shared: true,
                                        allow_copy: true)
        end
      end
      flash[:notice] = 'Your activity is now shared with other instructors within your schools.'
    rescue ActiveRecord::RecordInvalid
      flash[:error] = 'An error occurred while trying to share the activity.'
    end
    redirect_back(
      allow_other_host: false,
      fallback_location: instructor_mycontent_path(
        params[:program_id],
        display_lesson: params['display_lesson']
      )
    )
  end

  def set_activity_private
    begin
      school_ids = current_user.schools.pluck(:id)
      ActiveRecord::Base.transaction do
        SharedLibraryActivity
          .where(
            source_activity_id: @created_activity.id,
            school_id: school_ids,
            is_shared: true
          ).destroy_all
      end
      flash[:notice] = 'Your activity has been set to private.'
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'An error occurred while setting the activity to private.'
    end
    redirect_back(
      allow_other_host: false,
      fallback_location: instructor_mycontent_path(
        params[:program_id],
        display_lesson: params['display_lesson']
      )
    )
  end

  def remove_as_shared
    activity_title = @created_activity.title
    SharedLibraryActivity.cancel_shared_activity_request(@created_activity)
    flash[:notice] = "#{activity_title} has successfully been deleted."
    redirect_back(fallback_location: instructor_mycontent_path(params[:program_id],
                                                               display_lesson: params['display_lesson']))
  end

  def copy_to_mycontent
    activity_copy = MyContentActivityCopier.copy(@created_activity, current_user.id)

    if activity_copy.errors.empty?
      view_in_my_content_link = redirection_link(
        text: 'View in my content',
        path: instructor_mycontent_path(params[:program_id])
      )
      flash[:notice] = "Content successfully copied. #{view_in_my_content_link}".html_safe
    else
      flash[:errors] = activity_copy.errors.full_messages.join(', ')
    end

    redirect_to instructor_shared_content_path(program_id: params[:program_id], page: @page)
  end

  def path_to_section_activity(section)
    section_activity_path(popup: '1', section_id: section, id: @created_activity)
  end
  private :path_to_section_activity

  def redirect_to_assessment_or_content_toc(activity, in_institution_admin = false, section_id = nil, page: 1)
    if @from_my_content
      redirect_to instructor_mycontent_url(
        current_program,
        selected_lesson_ids: @created_activity.lesson,
        selected_strands: @created_activity.strand.title,
        filtered: true,
        page:
      )
    elsif activity.assessment? && in_institution_admin
      section = Section.find(section_id)
      redirect_to institution_admin_assessment_template_path(section.program.id,
                                                             section.course.id,
                                                             section_id,
                                                             display_lesson: activity.lesson,
                                                             toc_location: activity.toc_location)
    elsif activity.assessment?
      # We want only to go to the Assesment TOC if the save_action is not set or if it is set with the value 'exit'.
      if [nil, 'exit'].include? params.dig('instructor_created_activity', 'save_action')
        redirect_to instructor_assessments_path(current_program, toc_location_params(activity.lesson, activity.toc_location))
      else
        redirect_to edit_instructor_created_activity_path(instructor_created_activity_link_params(activity))
      end
    elsif in_institution_admin
      section = Section.find(section_id)
      redirect_to institution_admin_show_toc_template_path(section.program.id,
                                                           section.course.id,
                                                           section_id,
                                                           display_lesson: activity.lesson,
                                                           toc_location: activity.toc_location)
    elsif activity.has_rubric? && params.dig('_method') != 'delete'
      redirect_to edit_instructor_created_activity_path(instructor_created_activity_link_params(activity))
    else
      redirect_to instructor_toc_path(current_program, toc_location_params(activity.lesson, activity.toc_location))
    end
  end
  private :redirect_to_assessment_or_content_toc


  def show
    respond_to do |format|
      format.json @created_activity.to_json
    end
  end

  def confirm_destroy; end

  def destroy
    remover = InstructorActivityRemover.new(@created_activity).remove

    if remover.successful?
      flash[:success] = remover.message
    else
      flash[:error] = remover.message
    end

    redirect_to_assessment_or_content_toc(@created_activity)
  end

  def confirm_copy_previous_edition_igcs; end

  def copy_previous_edition_igcs
    # First we find/create an IgcCopyJob so we don't get again
    # warnings about previous edition activities to copy
    IgcCopyJob.find_or_create_by(
      src_program_id: @presenter.previous_program_edition.id,
      dest_program_id: @presenter.program.id,
      instructor_id: @presenter.current_user.id
    )

    SharedContent::CopyPreviousEditionIgcsWorker.perform_async(
      @presenter.previous_program_edition.id,
      @presenter.program.id,
      @presenter.current_user.id,
      @presenter.fetch_previous_edition_activities.pluck(:id)
    )

    flash[:notice] = 'All eligible activities will be copied.'
    redirect_to instructor_mycontent_path(program_id: @presenter.program.id)
  end

  def lesson
    @lesson ||= Lesson.find(lesson_id)
  end
  private :lesson

  def toc_location_params(lesson, toc_location)
    { :display_lesson => lesson.id,
      :start_unit     => lesson.unit.rank,
      :toc_location   => toc_location }
  end
  private :toc_location_params

  def assign_activity_list_header
    @activity_list_header = "#{lesson.display_name} | #{lesson.activity_list_header(toc_entry_id)}"
  end
  private :assign_activity_list_header

  private def lesson_toc_params
    {
      lesson_id: lesson_id,
      toc_entry_id: toc_entry_id
    }
  end

  private def lesson_id
    params[:override_lesson_id].presence || params[:lesson_id]
  end

  private def toc_entry_id
    params[:override_toc_entry_id].presence || params[:toc_entry_id]
  end

  private def assign_activity_params
    @activity_params = params.require(:instructor_created_activity)
      .permit(
        :assignment_group,
        :content_json,
        :direction_line,
        :draft,
        :hide_from_my_content,
        :language_code,
        :question_prompt,
        :rubric_json,
        :title,
        :student_title,
        :video_url,
        :video_platform
      ).merge(
        activity_type: @activity_type,
        instructor_id: current_user.id,
        references: permit_references_params
      ).merge(lesson_toc_params)

    language_code_blank = @activity_params[:language_code].blank?
    @activity_params[:language_code] = current_program.language_code if language_code_blank
  end

  private def remove_script_tags
    %i[title student_title direction_line].each do |act_attr|
      @activity_params[act_attr] = script_tag_sanitizer(@activity_params[act_attr]) unless @activity_params[act_attr].nil?
    end
  end

  private def permit_references_params
    references_params = params[:instructor_created_activity][:references]
    return '' unless references_params

    references_whitelist_attrs = %w[type body header recording_path instructor_media_item_id id]
    whitelist_hash = references_params.keys.each_with_object({}) do |key, memo|
      memo[key] = references_whitelist_attrs
    end
    references_params.permit(whitelist_hash)
  end

  private def assing_filtered_params
    uri = URI.parse(request.url)
    query_params = Rack::Utils.parse_nested_query(uri.query).symbolize_keys

    # Excludes the pagination in the params
    query_params.except!(:page)

    query_params.any? ? "?#{query_params.to_query}" : ""
  end

  private def assign_is_assessment_tab
    strand = lesson.strand_for_toc_location(toc_entry_id)
    @is_assessment_tab = Concept.find(strand.location)&.assessment?
  end

  def assign_activity_type
    @activity_type = params[:activity_type]
  end
  private :assign_activity_type

  def assign_created_activity
    @created_activity = InstructorCreatedActivity.find_by!(
      id: params[:id],
      hide_from_my_content: false
    )
  end
  private :assign_created_activity

  def activity_list_header(lesson)
    type = Activity.humanize_activity_type(params[:activity_type])
    header = lesson.activity_list_header(toc_entry_id)
    "#{lesson.display_name} | #{header} | #{type}"
  end
  private :activity_list_header

  def layout
    practice_layout
  end
  private :layout

  # Persist params through requests
  def url_options
    {:popup => params[:popup], :return_to => params[:return_to]}.merge(super)
  end

  def assign_from_my_content
    @from_my_content = params[:from_my_content] == 'true'
  end
  private :assign_from_my_content

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

  private def prevent_unauthorized_editing
    return unless current_user.id != @created_activity.instructor_id

    if request.xhr?
      render plain: NOT_AUTHORIZED_MESSAGE, status: 403
    else
      flash[:error] = NOT_AUTHORIZED_MESSAGE
      redirect_to_best_default_path
    end
  end

  private def set_page
    @page = params[:page] || 1
  end

  private def assign_menu_coords
    @menu_location = 'content'
  end

  # In order to display the activity preview when editing a rubric, some
  # data setup normally done in the activities controller or activity
  # presenter has to be done or stubbed enough to satisfy the views.
  private def assign_activity_preview_prerequisites
    # For composition activities
    assign_allowed_file_types

    # For group chat
    stub_class = Struct.new(:activity, :user, :section) do
      def group_chat_selection_config
        {
          group_maximum: activity.content_object.max_students_selection,
          group_minimum: activity.content_object.min_students_selection
        }
      end

      def track_time?
        false
      end

      def allow_audio_transcripts?
        return true if user.instructor?

        StudentInteractionSettings.new(user, section).audio_transcript
      end
    end

    @activity_presenter = stub_class.new(@activity, current_user, current_section)
  end

  private def prevent_content_sharing_access
    return if content_sharing_enabled_in_program?

    flash[:warning] = CONTENT_SHARING_DISABLED_MESSAGE
    redirect_to instructor_mycontent_path(
      params[:program_id]
    )
  end

  private def content_sharing_enabled_in_program?
    @content_sharing_enabled_in_program ||= begin
      school = current_focus.course&.school || current_user.schools&.first
      school.sharing_content_for_program?(current_program.id)
    end
  end
  helper_method :content_sharing_enabled_in_program?
end
