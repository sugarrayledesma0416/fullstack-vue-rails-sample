module ActivityViewable
  extend ActiveSupport::Concern
  include ApplicationHelper
  include ReturnLink
  include SmartbookActivityViewable

  ACTIVITY_TIMEOUT_DEFAULT = 60 * 3 * 1000 # in milliseconds

  included do
    helper_method :hide_footer_media_player? # This is temporary until the footer controls location story is complete.
  end

  def swf
    players_dir = File.dirname(__FILE__) + '/../../../public/players/'
    @swf_file = File.new(File.join(players_dir, params[:swf]), 'rb')
    response.content_type = 'application/x-shockwave-flash'
    render 'activities/swf', :layout => false
  end

  def image
    file_location = File.join(MediaItem::CDN_URL_PREFIX, 'zip_contents', params[:image]).to_s
    redirect_to file_location
  end

  def vocab_tutorial_iframe
    @activity.content_object.populate_dirs_from_media
    render 'activities/vocab_tutorial_iframe', :layout => false
  end

  def recording
    @activity = Activity.find(params[:id]).extend(ActivityViewDecorator)
    classwork = Classwork.new(current_user, current_section_id)

    attempt = classwork.find_or_new_attempt(@activity)
    @results = attempt.results if attempt

    content_object = @activity.content_object
    if content_object.class == MaestroActivityEngine::ActivityContent::CompositionRecordingContent
      @questions = content_object.items
      render :template => 'maestro_activity_engine/activities/data/composition_recording', :layout => false, :formats => [:xml]
    else
      @questions = content_object.questions
      @style = content_object.style
      @model = content_object.model
      render :template => 'maestro_activity_engine/activities/data/recording', :layout => false, :formats => [:xml]
    end
  end

  def common_prep(params)
    @activity ||= Activity.find(params[:id]).extend(ActivityViewDecorator)

    @angular_controller = 'studentActivityRequestsCtrl' # instructor views will override this
    @current_program ||= @activity.program

    # initialize vtext_linker
    @activity.initialize_vtext_linker(current_program, user_for_presenter, session:)

    assign_return_link

    @classwork = Classwork.new(user_for_presenter, current_section_id)
    @start_time = time_now_in_seconds
    @form_id = SecureRandom.uuid
    @timeout_override = ACTIVITY_TIMEOUT_DEFAULT
    @timeout_override = params[:timeout] unless params[:timeout].blank?
    @activity_submittable = true
    @course = current_user.instructor? ? current_focus&.course : current_section.course
    student_interaction_settings = StudentInteractionSettings.new(current_user, current_section)
    show_transcript = if program_has_audio_transcripts?
                        student_interaction_settings.audio_transcript || current_user.instructor?
                      else
                        false
                      end
    @transcript_settings = MaestroActivityEngine::TranscriptSettings.new(show_transcripts: show_transcript)

    yield if block_given?

    if @activity.content_object
      @activity.populate_activity_media

      if randomize_assessment?
        # Randomize activities and questions using the user id as a seed.
        # Using the user id as the seed ensures that the users will see the
        # same order of questions every time they view it, as they submit and
        # persist across page views, without needing to remember the order of
        # the questions as they were displayed the first time.
        @activity.randomize(current_user.id)
      elsif @activity.content_object.respond_to?(:randomize_choices)
        @activity.content_object.randomize_choices(current_user.id)
      end
    end

    if in_section?
      @activity.read_only = current_section.closed?
      @course = current_section.course
      @workset = @classwork.current_workset(@activity)
      if @workset.present?
        @workset_presenter = WorksetPresenter.new(@activity, @workset, vista_online_learning?)
        @workset.user = user_for_presenter
        @workset.section = current_section
      end
    else
      @workset = nil
    end

    # @score can be nil, the view helper has a fallback
    @score = if current_section.non_zero?
               GradebookEngine::GradebookAPI.find_student_grade(
                 activity_id: @activity.id,
                 section_id: current_section.id,
                 user_id: user_for_presenter.id
               )
             end
  end
  private :common_prep

  def in_section?
    # not safe just to check that current_section_id is not 0,
    # because if user specifies a section_id param for a nonexistent section,
    # current_section_id is non zero but current_section will return nil
    current_section && current_section.non_zero?
  end
  private :in_section?

  def time_now_in_seconds
    Time.now.utc.to_i
  end
  private :time_now_in_seconds

  # This is temporary until the footer controls location story is complete.
  # the footer media player was hiding the scores on decide and complete view.
  # This hides the media player on those views.
  def hide_footer_media_player?
    [:decide, :complete].include?(@activity_view)
  end

  def render(*args)
    @activity_view = args[0]
    super(*args)
  end

  def check_if_activity_in_study_plan
    @activity_presenter.activity_in_study_plan =
      request.referer.to_s.include?('study_plan_concept')
  end
  private :check_if_activity_in_study_plan
end
