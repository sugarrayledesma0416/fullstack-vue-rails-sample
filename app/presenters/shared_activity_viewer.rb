module SharedActivityViewer
  include AudienceLabeling
  include DateTimeHelper
  include ActionView::Helpers::TextHelper
  include RubricLinkable
  include ActivityStandardsLookup

  attr_reader :activity, :user, :section, :flash_notice, :notifications
  attr_writer :activity_in_study_plan
  attr_accessor :notifications

  DOUBLE_SECONDS = 120
  TO_MILLISECONDS = 1000

  delegate :partner_chat?, :submittable?, :solo_video_recording?,
           :solo_video_recording_or_included_in_multipart_activity?,
           :group_chat?, to: :activity
  delegate :rubric_graded?, to: :rubric_instructor_grading

  def initialize(activity, user, section, answer_key_mode: false)
    self.activity = activity
    self.user = user
    self.section = section
    @answer_key_mode = answer_key_mode
  end

  def answer_key_mode?
    @answer_key_mode
  end

  def find_or_create_attempt
    return @attempt if defined? @attempt

    if activity.question_bank?
      @attempt = Attempt.new
    else
      ruleset = (assignment && assignment.scoring_ruleset)
      @attempt = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id, ruleset)
      @attempt.disable_enhanced_feedback = (assignment && assignment.disable_enhanced_feedback?)
    end
    @attempt
  end

  def activity_in_study_plan?
    !!@activity_in_study_plan
  end

  def redirect_to_dashboard?(activity_complete = nil)
    if user&.instructor? || !activity.assessment?
      false
    elsif user.enrolled_in_section?(section)
      # redirect if unauthorized
      !assessment_authorized?(activity_complete)
    else
      true
    end
  end

  # TODO: Should be private
  def attempt_started?
    attempt && attempt.started?
  end

  def track_time?
    timed_assessment? && attempt_started?
  end

  def time_left?
    time_left_in_seconds > 0
  end

  def timed_assessment?
    user&.student? && activity.assessment? && assignment && assignment.timed?(user)
  end

  # TODO: delegate this
  def assessment?
    activity.assessment?
  end

  def randomize_assessment?
    user.student? && assessment? && assignment&.randomize_per_student?
  end

  # TODO: delegate this
  def time_left_in_seconds
    attempt.time_left_in_seconds
  end

  def original_time_limit
    assignment.time_limit * 60
  end

  # TODO: Just turn this into a constant.  Doesn't need a yaml file.
  def assessment_poll_interval
    ASSESSMENTS_CONFIG['sync_interval']
  end

  # TODO: delegate this
  def assessment_attempt_id
    attempt.id
  end

  def assessment_due_date
    format_date_time(assignment.due_date, :short_day_full_month) if assignment
  end

  def assessment_due_time
    zone = (user.time_zone != section.time_zone ? ' %Z' : '')
    assignment.due_time.strftime("%I:%M %p#{zone}") if assignment
  end

  def assessment_display_title
    "#{activity.title}".html_safe
  end

  def activity_component_name
    # Display "Practice" for a component
    # name when showing unlisted activities
    # for example, activities linked
    # to a study plan
    if activity.listed?
      activity.component_name
    else
      "Practice"
    end
  end

  def interaction_settings
    @interaction_settings ||= StudentInteractionSettings.new(user, section)
  end

  def allow_audio_transcripts?
    return true if user.instructor?

    interaction_settings.audio_transcript
  end

  def assessment_time_limit
    assessment_time_limit = assignment.time_limit_for_student(user)
    hours = assessment_time_limit / 60 # integer division give integer result
    minutes = assessment_time_limit % 60

    if hours > 0
      "#{hours} #{'hour'.pluralize(hours)}#{(minutes > 0 ? " #{minutes} minutes" : '')}"
    else
      "#{minutes} minutes"
    end
  end

  def has_audio?
    activity.icon.split(',').include?('audio') if activity.icon.present?
  end

  def standard_timeout_override
    #twice the assignment timelimit plus another hour to cover smaller time_limits
    #in milliseconds
    if assignment.assigned_assessment_detail
      (assignment.assigned_assessment_detail.time_limit * DOUBLE_SECONDS + 3600) * TO_MILLISECONDS
    end
  end

  def requires_unlocking?(unlocked_assessments)
    assessment_locked? && !(unlocked_assessments.include?(activity.id))
  end

  def requires_interstitial?(unlocked_assessments)
    user.student? &&
    activity.assessment? &&
    ( !attempt.started? ||  requires_unlocking?(unlocked_assessments))
  end

  # TODO: Remove the assignment.assigned_assessment_detail check, has_password?
  #       already does this.
  def assessment_locked?
    # non-assessment activities should not have passwords
    # Assignments pre-dating addition of assigned_assessment_detail will
    # also not have passwords. Instructors should not have to enter a password
    # in order to view an assignment.
    user.student? && activity.assessment? && assignment.assigned_assessment_detail && assignment.has_password?
  end

  # TODO: Should be private
  def assessment_authorized?(activity_complete)
    if assessment_assigned_and_released?
      # if activity_complete is nil, check the attempt
      if (activity_complete.nil? ? attempt.completed? : activity_complete)
        assessment_grade_available?
      else
        assessment_viewable?
      end
    else
      false
    end
  end

  def due_time_with_zone
    zone = (Time.zone.name != section.time_zone ? Time.use_zone(section.time_zone) { assignment.due_date_time.strftime('%Z') } : '')
    "#{format_date_time(assignment.due_date_time, :time_without_zone, section.time_zone)} #{zone}".html_safe
  end

  def ordinalized_due_date_time
    day = assignment.due_date_time.strftime("%d").to_i.ordinalize
    assignment.due_date_time.strftime("%B #{day} #{due_time_with_zone}").strip.html_safe
  end

  def activity_gradable?
    if assignment
      activity.gradable? && !assignment.category.credit_only?
    else
      activity.gradable?
    end
  end

  def attempts_remaining
    if attempt.present?
      pluralize(@attempt.attempt_track.remaining, 'attempt')
    else
      # TODO, this condition is unreachable.  If attempt returns nil
      # we get an undefined method `disable_enhanced_feedback=' for nil:NilClass
      # before we can get to this condition.
      'unlimited attempts'
    end
  end

  def activity_assigned?
    assignment.present?
  end

  def late_work_accepted?
    assignment.present? && assignment.category.accept_late_work?
  end

  def requires_ajax_submission?
    partner_chat? || group_chat?
  end

  private def assessment_has_been_graded?
    score = GradebookEngine::GradebookAPI.find_score(
      activity_id: activity.id,
      section_id: section.id,
      user_id: user.id
    )
    score && score.submitted_at.present? && !score.pending?
  end

  def assessment_grade_available?
    return @assessment_grade_available if defined? @assessment_grade_available

    @assessment_grade_available = assignment&.assessment_grade_available?

    @flash_notice = grade_availability_description unless @assessment_grade_available
    @assessment_grade_available
  end
  private :assessment_grade_available?

  # TODO: should be private
  def assessment_viewable?
    if section && activity.assessment?
      display_assessment_prior_grading?
    else
      # This condition can't be reached because this method is only called
      # from within methods that verify we have a section and the activity
      # is an assessment.
      true
    end
  end

  # TODO: should be private
  def display_assessment_prior_grading?
    if assessment_has_been_graded? && attempt.completed?
      @flash_notice = grade_availability_description unless assessment_grade_available?
      assessment_grade_available?
    else
      true
    end
  end

  def grade_availability_description
    return '' if assessment_grade_available?

    message = "Your #{instructor_label} has chosen not to allow students " \
              'to view their full results for this ' \
              "#{activity.strand_singular_label || 'activity'}"

    case assignment.grade_availability
      when :on_release
        message << " until he/she releases them.  Please try again later."
      when :on_grading
        message << " until all students have been graded.  Please try again later."
      when :on_specific_date
        message << " until after " + assignment.grades_available_at.strftime("%a, %b #{assignment.grades_available_at.day.ordinalize} %I:%M %p.") + ". Please try again at that time."
      when :on_due_date
        message << " until after " + assignment.due_date.strftime("%a, %b #{assignment.due_date.day.ordinalize} %I:%M %p.") + ". Please try again at that time."
      when :never
        message << "."
    end
  end

  # TODO: Should be private
  def assessment_assigned_and_released?
    if section && activity.assessment?
      assigned_and_released = assignment && assignment.shown?
      unless assigned_and_released
        @flash_notice = "The #{activity.strand_singular_label || 'activity'} " \
                        'you tried to access has not yet been enabled by ' \
                        "your #{instructor_label}."
      end
      assigned_and_released
    else
      true
    end
  end

  def track_group
    assignment && assignment.track_group
  end

  def video_settings
    settings = MaestroActivityEngine::VideoSettings.new(
      all_enabled = true,
      is_english: activity.english?
    )
    if user.student?
      if user.enrolled_in_section?(section)
        settings.subtitle_languages      = interaction_settings.video_subtitle_languages
        settings.transcript_languages    = interaction_settings.video_transcript_languages
        settings.allow_popup_translation = course.allow_video_popup_translation?
      else
        settings.subtitle_languages      = 'foreign'
        settings.transcript_languages    = 'foreign'
      end
    end
    settings
  end

  def should_show_answers?
    if activity.assessment?
      return true if user.instructor?
      return false if section.nil? #don't ever show student answers to assessments if they're not in a section
      return false if assignment.blank? #don't show answers if the assessment is not assigned
    end
    return true #don't ever hide answers for non-assessments
  end

  def activity_list_header
    header = ''
    if activity.lesson && activity.toc_location
      lesson = activity.lesson
      header += "#{lesson.display_name} | #{lesson.activity_list_header(activity.toc_location)}"
    end
    header
  end

  def lesson_header
    return {} if activity.question_bank?

    lesson = activity.lesson
    strand = lesson.strand_for_toc_location(activity.toc_location)
    substrand = lesson.substrand_for_toc_location(activity.toc_location)

    {
      lesson: lesson.display_name,
      strand: strand && strand.name,
      substrand: substrand && substrand.name
    }
  end

  def pretest_type
    return 'video' if activity.include_video_recording?
    return 'audio' if activity.include_audio_recording?
  end

  def partner_chat_roster
    @partner_chat_roster ||= PartnerChatRoster.new(user, course, activity)
  end

  private def instructor_label
    @instructor_label ||= audience_label(section&.program&.audience, :instructor)
  end

  def format_rubric_completed_link(link_text)
    rubric_graded? ? format_rubric_link(link_text, 'none') : nil
  end

  private def format_rubric_path
    rubric_section_activity_path(
      section.id,
      activity.id,
      from: 'activity'
    )
  end

  private def rubric_instructor_grading
    RubricInstructorGrading.new(
      activity.id,
      section.id,
      user.id
    )
  end

  private

  # we want to be able to use this to assign using the self.* syntax
  # but we don't want outside influences to be able to set these
  attr_writer :activity, :user, :section, :notifications


  def attempt
    # memoized in this method
    find_or_create_attempt
  end

end
