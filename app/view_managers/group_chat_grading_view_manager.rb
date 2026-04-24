class GroupChatGradingViewManager
  attr_reader :presenter, :student, :question

  def initialize(presenter, student, question)
    @presenter = presenter
    @question = question
    @student = student
  end

  def feedback_for(lookup_student)
    presenter.feedback[presenter.response_id(lookup_student, question)]
  end

  def recording_path_for(lookup_student)
    presenter.recording_path(lookup_student, question)
  end

  def video_container_id
    "group_chat_container_#{student.id}_#{presenter.teammates.map(&:id).join('_')}"
  end
end
