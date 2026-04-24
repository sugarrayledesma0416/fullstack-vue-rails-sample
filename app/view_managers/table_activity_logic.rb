module TableActivityLogic
  TABLE_AUTOGRADED_QUESTION_CLASSES = [
    MaestroActivityEngine::ActivityContent::TableActivity::TableFillInTheBlank::Item,
    MaestroActivityEngine::ActivityContent::TableActivity::TableDropDown::Item
  ].freeze
  TABLE_INSTRUCTOR_GRADED_QUESTION_CLASSES = [
    MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
  ].freeze
  TABLE_QUESTION_CLASSES = TABLE_AUTOGRADED_QUESTION_CLASSES +
                           TABLE_INSTRUCTOR_GRADED_QUESTION_CLASSES

  def table_activity?
    activity.activity_type == 'table_activity'
  end

  def inline_open_ended_table_question?(object = nil)
    question_object = object || question

    question_object.is_a?(
      MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
    )
  end

  def auto_graded_table_question?
    TABLE_AUTOGRADED_QUESTION_CLASSES.any? do |klass|
      question.is_a?(klass)
    end
  end

  def table_activity_question?(object = nil)
    question_object = object || question

    TABLE_QUESTION_CLASSES.any? do |klass|
      question_object.is_a?(klass)
    end
  end
end
