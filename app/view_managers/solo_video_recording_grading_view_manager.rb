class SoloVideoRecordingGradingViewManager
  attr_accessor :presenter, :student, :question

  def initialize(presenter, student, question)
    self.presenter = presenter
    self.question = question
    self.student = student
  end

  def student_feedback
    presenter.feedback[presenter.response_id(student, question)]
  end

  def student_recording_path
    presenter.recording_path(student, question)
  end

  # id string that uniquely identifies a jwplayer container on the grading page"
  def video_id
    "solo_video_recording_container_#{student.id}"
  end
end
