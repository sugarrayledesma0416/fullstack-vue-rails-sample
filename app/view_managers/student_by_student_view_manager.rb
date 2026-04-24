class StudentByStudentViewManager
  include CommonGradingViewLogic
  include StudentOrQuestionDropdownLogic
  attr_accessor :presenter
  delegate :current_student, :current_student_attempts, :current_student_attempt, :grading_set,
           :instructor_feedback, :disable_controls?, :activity_composition?,
           :question_to_grade_view_manager, :students_to_grade, :students_with_pending_grade,
           :student_pending_question?, :current_student_number, :feedback, to: :presenter

  def initialize(presenter)
    @presenter = presenter
  end

  def language
    activity.content_object.language
  end

  def has_mixed_grading_method?
    activity.has_mixed_grading_method?
  end

  def recording_activity?
    activity.recording_activity?
  end

  def activity_references
    activity.content_object.references.select{ |ref| ref.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base) }
  end

  def currently_on_first_student?
    current_student == students_to_grade.first
  end

  def currently_on_last_student?
    current_student == students_to_grade.last
  end

  def current?(student)
    current_student == student
  end

  def graded?(student)
    students_with_pending_grade.exclude?(student.id)
  end

  def option_string(student)
    "##{student.id.to_s}"
  end

  def option_value(student)
    student.id
  end

  alias_method :option_jump_to, :option_value

  def option_data(student)
    { student_name: student.full_name,
      student_number: option_string(student) }
  end

  def questions_to_grade
    if activity.smart_book?
      results = current_student_attempt.results
      presenter.questions_to_grade.select do |question|
        results.has_response?(question.label)
      end
    else
      presenter.questions_to_grade
    end
  end
end
