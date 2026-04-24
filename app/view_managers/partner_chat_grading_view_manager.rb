class PartnerChatGradingViewManager
  attr_reader :presenter, :student, :question

  def initialize(presenter, student, question)
    @presenter = presenter
    @question = question
    @student = student
  end

  def student_on_left
    presenter.original_user(student)
  end

  def student_on_right
    presenter.original_partner(student)
  end

  def student_on_left_feedback
    presenter.feedback[presenter.response_id(student_on_left, question)]
  end

  def student_on_right_feedback
    presenter.feedback[presenter.response_id(student_on_right, question)]
  end

  def student_on_left_recording_path
    presenter.recording_path(student_on_left, question)
  end

  def student_on_right_recording_path
    presenter.recording_path(student_on_right, question)
  end

  def video_id
    "partner_chat_container_#{student_on_left.id}_#{student_on_right.id}"
  end
end
