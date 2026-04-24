class StudentResponseForInlineWolViewManager < StudentResponseForQuestionViewManager
  def response_id
    "#{question.label}_student_#{student.id}"
  end

  private def question_label
    question.label
  end
end
