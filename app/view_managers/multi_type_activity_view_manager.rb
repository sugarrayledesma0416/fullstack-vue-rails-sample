class MultiTypeActivityViewManager
  include CommonGradingViewLogic
  include TableActivityLogic

  delegate :current_student, :current_student_attempt, to: :presenter
  attr_accessor :presenter

  def initialize(presenter)
    @presenter = presenter
  end

  def feedback_item(question)
    feedback[current_response_id(question)]
  end

  def recording_path(question)
    presenter.recording_path(current_student, question)
  end

  def new_recording?(question)
    presenter.new_recording?(current_student, question)
  end

  def results(question_label = nil)
    current_student_attempt.results_for_question(question_label)
  end

  def sub_activities
    presenter.activity.sub_activities
  end

  delegate :activity, to: :presenter
end
