module AutoGradedQuestionCheckable
  AUTO_GRADED_QUESTION_CLASSES = [
    MaestroActivityEngine::ActivityContent::DropDown::Item,
    MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item,
    MaestroActivityEngine::ActivityContent::MultipleAnswer::Item,
    MaestroActivityEngine::ActivityContent::MultipleChoice::Item,
    MaestroActivityEngine::ActivityContent::MultipleChoiceSame::Item,
    MaestroActivityEngine::ActivityContent::TableActivity::TableDropDown::Item,
    MaestroActivityEngine::ActivityContent::TableActivity::TableFillInTheBlank::Item
  ].freeze

  private def auto_graded_question?(question)
    AUTO_GRADED_QUESTION_CLASSES.any? { |klass| question.instance_of?(klass) } ||
      (question.is_a?(Smartbook::Response) && !question.instructor_gradable?)
  end
end
