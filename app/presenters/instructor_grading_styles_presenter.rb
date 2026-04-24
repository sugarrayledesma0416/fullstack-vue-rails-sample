class InstructorGradingStylesPresenter
  attr_accessor :program, :activity, :task_type, :instructor, :focus, :errors

  delegate :grading_method, :instructor_graded?, to: :activity
  delegate :can_use_ai_grading_suggestions?, :ai_grading_suggestions_enabled?, to: :instructor

  def initialize(opts)
    self.instructor = opts[:instructor]
    self.task_type = opts[:task_type]
    self.focus = opts[:focus]
    self.program = opts[:program]
    self.activity = Activity.find_by_id(opts[:activity_id])
    self.errors = []
    unless activity
      self.errors << "Activity ID##{opts[:activity_id]} not found."
    end
  end

  def valid?
    errors.empty?
  end

  def error_messages
    errors.join(' ')
  end

  def section
    focus.section || focus.sections.first
  end

  def grading_style
    instructor.setting(Setting::GradingTasks::GradingStyle)
  end

  def activity_list_header
    activity.list_header
  end

  def classwork
    activity.classwork_for(instructor, section)
  end

  def attempt
    activity.attempt_for(instructor, section)
  end

  def attempt_track
    activity.attempt_track_for(instructor, section)
  end

  def ai_grading_feature_enabled?
    program.ai_grading_feature_enabled? || can_use_ai_grading_suggestions?
  end

  def ai_grading_available?
    ai_grading_feature_enabled? && (activity.composition? || activity.open_ended?)
  end

  private def grading_set
    @grading_set ||= GradingSet.by_program_and_instructor_and_activity(program, instructor, activity)
  end

  def grading_complete?
    @grading_set.complete?(focus.sections) if grading_set
  end

  private def student_ids
    GradingSetStudentList.new(
      activity_id: activity.id,
      section_ids: focus.sections.pluck(:id),
      unassigned: task_type == GradingTask::UNASSIGNED_ACTIVITIES,
      students: focus.students
    ).user_ids
  end

  private def any_activity_revision_with_rubric?
    return @has_rubric_revision if defined? @has_rubric_revision

    if activity.instructor_created?
      @has_rubric_revision = activity.show_rubric?
    else
      attempts = Attempt.find_submitted_attempts_for_activities(
        student_ids,
        focus.sections.pluck(:id),
        activity
      )

      @has_rubric_revision = attempts.map(&:cms_revision_id).uniq.any? do |cms_revision_id|
        Activity.find_by(cms_revision_id:)&.show_rubric?
      end
    end
  end

  def grading_set_button_text
    grading_complete? ? 'review' : 'start grading'
  end

  def hide_question_by_question_input?
    activity.activity_type == 'ai_virtual_chat' ||
      activity.activity_type == 'checkbox_survey' || (
      activity.activity_type == 'table_activity' &&
      activity.instructor_graded_questions.present?
    )
  end

  def q_by_q_disabled?
    any_activity_revision_with_rubric? || activity.group_chat?
  end

  def q_by_q_disabled_msg
    if any_activity_revision_with_rubric?
      return 'This activity can’t be graded Question by Question.'
    end

    'Group Chats can only be graded Student by Student.' if activity.group_chat?
  end

  def section_video_transcript_languages
    section.video_transcript_languages.presence || section.course.video_transcript_languages
  end

  def section_video_subtitle_languages
    section.video_subtitle_languages.presence || section.course.video_subtitle_languages
  end

  def section_audio_transcript
    section.audio_transcript.nil? ? section.course.allow_audio_transcripts : section.audio_transcript
  end

  def audio_transcript_display
    section_audio_transcript ? 'On' : 'Off'
  end

  def video_subtitle_languages_display
    display_language_name(section_video_subtitle_languages)
  end

  def video_transcript_languages_display
    display_language_name(section_video_transcript_languages)
  end

  def display_language_name(setting_value)
    if setting_value == 'foreign'
      program.language_name
    elsif setting_value == 'foreign_and_english'
      if program.language_code == 'en'
        program.language_name
      else
        "#{program.language_name} and English"
      end
    else
      'Off'
    end
  end
end
