class ReviewWorkPresenter
  include SharedInstructorGrading
  include AI::GradingSuggestionsForAttempts
  include RubricLinkable

  attr_reader :current_student_attempt, :current_student,
              :recording_path_prefix, :score, :instructor
  attr_accessor :chat_presenter, :composition_attachment

  delegate :original_user, :original_partner,
           :partner_is_not_practicing?, :partner_is_practicing?,
           to: :chat_presenter
  delegate :composition?, to: :activity, prefix: true
  delegate :accent_bar?, :language, :content_object, :has_rubric?, to: :activity
  delegate :can_use_ai_grading_suggestions?, :ai_grading_suggestions_enabled?, to: :instructor

  def initialize(instructor, score, attempts_hash)
    @instructor = instructor
    @score = score
    @current_student_attempt = attempts_hash[:current_student_attempt]
    @current_student = attempts_hash[:current_student_attempt].user
    @questions_to_grade = nil
    @teammate_attempts = []

    # ensure attempt is working with the same activity object
    @current_student_attempt.activity = activity

    # covered by cuke in features/gradebook_single_student.feature:82
    activity.ensure_correct_version(@current_student_attempt.cms_revision_id)

    if activity.partner_chat?
      prep_chat_presenter(PartnerChatPresenter)
    elsif activity.group_chat?
      prep_chat_presenter(GroupChatPresenter)
    end
  end

  def ai_grading_feature_enabled?
    section.program.ai_grading_feature_enabled? || can_use_ai_grading_suggestions?
  end

  def has_practice_test_recommendations?
    activity.activity_type == 'practice_test'
  end

  # We will show comments and student names by default for chat or recording activities.
  def show_comments
    @activity.chat_or_recording?
  end
  alias_method :show_student_names, :show_comments

  # These are the checkboxes for toggling student name and comment visibility
  def show_instructor_display_controls?
    @activity.activity_type == 'checkbox_survey' ? false : true
  end

  def question_to_grade_view_manager(question)
    QuestionToGradeViewManager.new(self, question)
  end

  def multi_type_activity_view_manager
    MultiTypeActivityViewManager.new(self)
  end

  def questions_to_grade
    @questions_to_grade ||=
      if activity.santillana?
        @current_student_attempt.smartbook_responses.answered
      else
        activity.questions
      end
  end

  def students_to_submit
    ([current_student] + teammates).compact
  end

  def gradeable?(student)
    attempt = if student == current_student
                current_student_attempt
              else
                @teammate_attempts.detect do |teammate_attempt|
                  teammate_attempt.user_id == student.id
                end
              end

    instructor.gradeable_sections.include?(attempt.section) if attempt
  end

  def attempts_by_user_id
    @attempts_by_user_id ||= attempts.inject({}){ |memo, attempt| memo[attempt.user_id.to_s] = attempt; memo }
  end

  def score_reload
    @score = GradebookEngine::GradebookAPI.find_score(
      activity_id: activity.id,
      section_id: section.id,
      user_id: current_student.id
    )
  end

  def student_attempts
    { current_student.id => @current_student_attempt }
  end

  def activity
    @activity ||= Activity.find(score.activity_id)
  end

  def section
    @section ||= Section.find(score.section_id)
  end

  def sections
    attempts.map(&:section).uniq
  end

  def teammates
    @teammates ||= current_student_attempt.teammates_from_results || []
  end

  private def prep_chat_presenter(chat_class)
    @chat_presenter = chat_class.new(
      [@current_student_attempt.results.first[:response]]
    )
    set_teammates_attempts
  end

  private def set_teammates_attempts
    @teammate_attempts = (current_student_attempt.teammates_from_results || []).map do |team_mate_user|
      teammate_attempt(
        team_mate_user,
        current_student_attempt,
        activity
      )
    end.compact
  end

  private def attempts
    ([@current_student_attempt] + @teammate_attempts).compact
  end

  private def grading_feedback
    @grading_feedback ||= GradingFeedback.new(activity: activity,
                                              questions: questions_to_grade,
                                              students: students,
                                              sections: sections)
  end

  private def students
    ([@current_student] + teammates).compact
  end

  # For vhl-authored activities (that have a cms_revision_id) include
  # the cms_revision_id of the attempt currently being graded in the
  # parameters for the link to view the rubric.
  private def format_rubric_path
    rubric_params = { from: 'grading', id: activity.id, section_id: 0 }
    unless activity.instructor_created?
      rubric_params[:cms_revision_id] = current_student_attempt.cms_revision_id
    end
    rubric_section_activity_path(rubric_params)
  end
end
