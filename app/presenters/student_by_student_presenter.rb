# Usage: StudentByStudentPresenter.new(grading_set, program, sections, params).prepare
class StudentByStudentPresenter < InstructorGradingSetsPresenter
  include RubricLinkable
  include AI::GradingSuggestionsForAttempts

  attr_reader :teammates
  delegate :original_user, :original_partner, :partner_is_not_practicing?,
           :partner_is_practicing?, to: :chat_presenter
  attr_accessor :composition_attachment, :teammate_attempts
  delegate :has_rubric?, to: :activity

  # Signature of this constructor changed in commit fd3eb34b, but its unit tests were not updated
  def initialize(
    instructor,
    grading_set,
    program,
    sections,
    instructor_grading_tasks_presenter,
    params,
    show_auto_graded_questions
  )
    super(instructor, grading_set, program, sections, params, show_auto_graded_questions)
    @instructor_grading_tasks_presenter = instructor_grading_tasks_presenter
    @teammates = []
  end

  # this must be run before accessing other methods
  def prepare
    unless students_to_grade.empty?
      assign_activity_revision
      if activity_partner_chat?
        prepare_for_partner_chat
      elsif activity_group_chat?
        prepare_for_group_chat
      end
    end
    self
  end

  # We want to grade all the activity questions or all the instructor-graded
  # interactions answered by at least one student for a smartbook activity.
  alias :questions_to_grade :activity_questions

  def has_nothing_to_grade?
    student_attempts.blank?
  end

  def question_to_grade_view_manager(question)
    QuestionToGradeViewManager.new(self, question)
  end

  def multi_type_activity_view_manager
    MultiTypeActivityViewManager.new(self)
  end

  def page_title
    'Grading Student by Student'
  end

  def current_student
    return @current_student if defined? @current_student

    @current_student = if params[:student_id]
                         students_to_grade.detect do |student|
                           student.id.to_s == params[:student_id].to_s
                         end
                       end
    @current_student ||= students_to_grade.first

    if @current_student
      @current_student.my_current_section = @current_student.most_relevant_section(@sections)
    end

    @current_student
  end

  def current_student_attempt
    return @current_student_attempt if defined? @current_student_attempt

    @current_student_attempt = student_attempts[current_student&.id&.to_s]
  end

  def done?
    done_early? || next_student == :no_next_element_found
  end

  def grading_status
    @grading_status ||= @grading_set.grading_status_of_students(activity, sections)
  end

  def instructor_feedback
    return @instructor_feedback if defined? @instructor_feedback

    @instructor_feedback = if current_student_attempt
                             feedback.general_feedback(current_student)
                           end
  end

  def last_item?
    current_student == students_to_grade.last &&
      @params[:commit] != '< Save & Previous' &&
      @params[:jump_to].blank?
  end

  def next_element
    { student_id: next_student.id }
  end

  def student_attempts
    # refactor this so that student answers are results objects
    # possible further refactor, add presenter methods to simplify view access to results
    @student_attempts ||= Attempt.find_submitted_attempts_for_activity_and_students(@sections, students_to_grade, @activity)
  end

  def students_with_pending_grade
    # StudentByStudentViewManager#graded? evaluates a student as "graded"
    # if the student is not in the list returned here. If the current
    # task is "already graded", though, the student _will_ be in the list,
    # and graded? will evaluate incorrectly as false. In that case,
    # returning an empty list guarantees that the student will not be in
    # the list.
    if params[:task_type] == GradingTask::ALREADY_GRADED
      []
    else
      task_set = @instructor_grading_tasks_presenter.task_set(@instructor_grading_tasks_presenter.current_task)
      task_set.students_for_activity(activity)
    end
  end

  private def prepare_for_partner_chat
    @chat_presenter = PartnerChatPresenter.new(chat_responses)

    # We need to sort students_to_grade so that users appear first, partners second
    @students_to_grade = @chat_presenter.sort_students(@students_to_grade)

    # Re-fetch current_student and teammate when not grading a particular student
    # This happens when we are grading the first student in a grading set.
    unless params[:student_id]
      @current_student = students_to_grade.first
    end

    # Fetch teammate information
    @teammates = User.where(id: teammate_id)
    @teammate_attempt = teammate_attempt(
                          @teammates,
                          current_student_attempt,
                          activity
                        )
    if @teammate_attempt.nil?
      @teammate_attempts = {}
    else
      @teammate_attempts = @teammates.each_with_object({}) do |team_mate, hash|
        hash[team_mate] = @teammate_attempt
      end
      add_attempt_section_when_missing(@teammate_attempt)
    end
  end

  # TODO: Concurrent enrollment: a teammate may have multiple group‑chat attempts
  # across @possible_section_ids. The current selection (group_by(&:user_id).transform_values(&:first))
  # arbitrarily picks one. Replace with logic that selects the attempt matching the current chat/section context
  private def prepare_for_group_chat
    @chat_presenter = GroupChatPresenter.new(chat_responses)
    @students_to_grade = @chat_presenter.sort_students(@students_to_grade)
    @current_student = students_to_grade.first unless params[:student_id]
    @teammates = ([chat_response.user] + chat_response.partner_users.values).reject do |team_mate|
      team_mate == current_student
    end
    @possible_section_ids = possible_section_ids(current_student_attempt)

    attempts_by_user = Attempt.active
                              .by_student(*@teammates)
                              .by_section(*@possible_section_ids)
                              .by_activities(activity)
                              .order(:id)
                              .group_by(&:user_id)
                              .transform_values(&:first)

    @teammate_attempts = @teammates.each_with_object({}) do |teammate, hash|
      hash[teammate] = attempts_by_user[teammate.id]
      add_attempt_section_when_missing(hash[teammate]) if hash[teammate].present?
    end
  end

  private def assign_activity_revision
    attempt = Attempt.active_attempt(current_student, current_student.my_current_section, activity)
    activity.ensure_correct_version(attempt.cms_revision_id) if attempt
  end

  private def current_user_is_original_user?
    chat_response.user == current_student
  end

  private def grading_feedback
    return @grading_feedback if defined? @grading_feedback

    students = [current_student]

    # Get the feedback for the teammate when grading a partner chat or group chat
    students += teammates if activity.partner_chat? || activity.group_chat?

    @grading_feedback = GradingFeedback.new(
      activity: @grading_set.activity,
      questions: questions_to_grade,
      students: students,
      sections: sections
    )
  end

  private def jump_target(grading_list, jump_to)
    grading_list.detect { |student| student.id.to_s == jump_to }
  end

  private def next_student
    @next_student ||= get_grading_list_element(
      students_to_grade, current_student, @params[:jump_to]
    )
  end

  private def chat_responses
    @chat_responses ||= student_attempts.values.map do |attempt|
      attempt.results.first[:response]
    end.uniq
  end

  private def chat_response
    @chat_response ||= current_student_attempt.results.first[:response]
  end

  private def teammate_id
    if current_user_is_original_user?
      chat_response.partner_id
    else
      chat_response.user_id
    end
  end

  # For vhl-authored activities (that have a cms_revision_id) include
  # the cms_revision_id of the attempt currently being graded in the
  # parameters for the link to view the rubric.
  # The same parameter will be used for Instructor copies of vhl-authored
  # activities, to load the correct version of the rubric that was in place
  # when the student submitted the activity. Since for those activities
  # the attempt.cms_revision_id has the value of the Activity.instructor_revision_id
  private def format_rubric_path
    rubric_params = { from: 'grading', id: activity.id, section_id: 0 }
    rubric_params[:cms_revision_id] = current_student_attempt.cms_revision_id
    rubric_section_activity_path(rubric_params)
  end
end
