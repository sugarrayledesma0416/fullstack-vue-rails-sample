# Usage: QuestionByQuestionPresenter(grading_set, program, sections, params_hash).prepare
class QuestionByQuestionPresenter < InstructorGradingSetsPresenter
  include AutoGradedQuestionCheckable
  include AI::GradingSuggestionsForAttempts

  attr_accessor :composition_attachment, :teammate_attempts, :current_student

  delegate :original_user, :original_partner, :partner_is_not_practicing?,
           :partner_is_practicing?, to: :chat_presenter

  def initialize(instructor, grading_set, program, sections, params, show_auto_graded_questions)
    super(instructor, grading_set, program, sections, params, show_auto_graded_questions)
  end

  # this must be run before accessing other methods
  def prepare
    assign_activity_revision

    if questions_to_grade.present?
      @teammates = {}
      assign_teammates if activity.partner_chat?

      assign_students_by_grade_status

      if activity.partner_chat?
        # Filter out students who are partners so there aren't duplicate grading rows
        filter_students
      end
    end
    self
  end

  def has_nothing_to_grade?
    student_attempts.blank?
  end

  def page_title
    'Grading Question by Question'
  end

  def true_false_enhanced_graded_question?(student)
    activity.true_false_enhanced? &&
      !question_pending?(current_question.label, student_attempt(student))
  end

  def questions_to_grade
    @questions_to_grade ||= filter_questions_to_grade
  end

  def filter_questions_to_grade
    return pending_questions if activity.true_false_enhanced?
    if show_auto_graded_questions?
      activity_questions
    else
      activity_questions.reject { |question| auto_graded_question?(question) }
    end
  end
  private :filter_questions_to_grade

  def pending_questions
    activity_questions.each_with_object([]) do |question, memo|
      students.each do |student|
        if question_pending?(question.label, student_attempt(student))
          memo << question
          break
        end
      end
    end
  end
  private :pending_questions

  def current_question
    return @current_question if @current_question
    @current_question = questions_to_grade.detect{|question| question.label == params[:question_label]} if params[:question_label]
    @current_question ||= questions_to_grade.first
  end

  def done?
    done_early? || next_question == :no_next_element_found
  end

  def grading_status
    @grading_status ||= @grading_set.grading_status_of_questions(activity_questions)
  end

  def last_item?
    current_question == questions_to_grade.last &&
      @params[:commit] != '< Save & Previous' &&
      @params[:jump_to].blank?
  end

  def next_element
    { :question_label => next_question.label }
  end

  def partner_chat_responses
    @partner_chat_responses ||= students.map do |student|
      student_attempt(student).results.first[:response]
    end
  end

  def student_attempts
    # refactor this so that student answers are results objects
    # possible further refactor, add presenter methods to simplify view access to results
    @student_attempts ||= Attempt.find_submitted_attempts_for_activity_and_students(@sections, students, activity, true)
  end

  def student_attempt(student)
    student_attempt = student_attempts[student.id.to_s]
    if student_attempt.nil?
      debug_student_attempt(student)
    end

    student_attempt
  end

  def has_student_attachment?(student, question)
    question.class.module_parents.include?(MaestroActivityEngine::ActivityContent::Composition) &&
      student_attempt(student).attachment_for(question.label)
  end

  def students
    students_to_grade + students_graded
  end

  def students_to_submit
    submit_students = students
    submit_students += @teammates.values if activity.partner_chat?
    submit_students
  end

  def students_graded
    @students_graded ||= []
  end

  def teammate(student)
    @teammates[student]
  end

  def assign_students_by_grade_status
    @students_graded = []

    students_to_grade.each do |student|
      feedback_points = feedback.question_points(student, current_question.label)
      if feedback_points
        @students_graded << students_to_grade.delete(student)
      end
    end
  end
  private :assign_students_by_grade_status

  def assign_teammates
    @teammate_attempts = {}

    teammate_ids = students.map { |student| teammate_id(student) }.uniq
    teammates_by_id = User.where(id: teammate_ids).index_by(&:id)

    students.each do |student|
      teammate = teammates_by_id[teammate_id(student)]

      next unless teammate

      teammate_attempt = teammate_attempt(
                           teammate,
                           student_attempt(student),
                           activity
                         )
      @teammates[student] = teammate
      unless teammate_attempt.nil?
        @teammate_attempts[teammate] = teammate_attempt
        add_attempt_section_when_missing(teammate_attempt)
      end
    end

    @chat_presenter = PartnerChatPresenter.new(partner_chat_responses)
  end
  private :assign_teammates

  def original_partner?(student)
    original_partner(student) == student
  end

  def original_user_in_grading_set?(student)
    user = original_user(student)
    @students_to_grade.include?(user) || @students_graded.include?(user)
  end

  def filter_students
    # Filters out users who were the original partner in a partner
    # chat when their collaborator is in the grading set.
    student_filter = lambda { |student| original_partner?(student) && original_user_in_grading_set?(student) }

    @students_to_grade.to_a.reject! do |student|
      student_filter.call(student)
    end

    @students_graded.to_a.reject! do |student|
      student_filter.call(student)
    end
  end

  def question_to_grade_view_manager(question, student)
    self.current_student = student
    QuestionToGradeViewManager.new(self, question)
  end

  private def grading_feedback
    @grading_feedback ||= GradingFeedback.new(
      activity: @grading_set.activity,
      questions: current_question,
      sections: sections,
      students: students + @teammates.values
    )
  end

  def jump_target(grading_list, jump_to)
    grading_list.detect{ |question| question.label == jump_to }
  end
  private :jump_target

  def next_question
    @next_question ||= get_grading_list_element(questions_to_grade, current_question, @params[:jump_to])
  end
  private :next_question

  def teammate_id(student)
    response = student_attempt(student).results.first[:response]

    if response.user_id == student.id
      response.partner_id
    else
      response.user_id
    end
  end
  private :teammate_id

  # To make sure that we can grade all of the questions that the students submitted,
  #   rather than just the questions in the latest activity revision, we assign the
  #   revision ID from the student attempts to the activity. This is based on a
  #   similar method of the same name in StudentByStudentPresenter.
  def assign_activity_revision
    # Because this is the question-by-question presenter, we expect that all attempts
    #   have the same revision ID.
    attempt = student_attempts.values.first
    activity.ensure_correct_version(attempt.cms_revision_id) if attempt
  end
  private :assign_activity_revision

  # These activity types do not use a review partial.
  def render_student_response_for_question?
    [
      MaestroActivityEngine::ActivityContent::OpenEnded::Item,
      MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item,
      Smartbook::Response,
      MaestroActivityEngine::ActivityContent::Recording::Question
    ].any? { |klass| current_question.is_a?(klass) }
  end

  # We will not show any rubric information in QxQ grading.
  def has_rubric?
    false
  end

  private def debug_student_attempt(student)
    VHLMonitor.error(
      'Student attempt not found',
      student_id: student.id,
      available_attempts: student_attempts.keys,
      sections: @sections.pluck(:id),
    )
  end
end
