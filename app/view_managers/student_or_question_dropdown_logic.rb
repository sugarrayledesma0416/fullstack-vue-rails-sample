module StudentOrQuestionDropdownLogic
  def checkmark_image_path(checked)
    path = 'music/v1/icons/core/checkmark'
    if checked
      path = "#{path}.svg"
    else
      path = "#{path}_none.svg"
    end
    ActionController::Base.helpers.asset_path(path)
  end

  def graded_string(question_or_student)
    if graded?(question_or_student)
      ' (graded)'
    else
      ''
    end
  end

  def option_hash(question_or_student)
    { value: option_value(question_or_student),
      selected: current?(question_or_student),
      data: ({
        jump_to: option_jump_to(question_or_student),
        grade_listing_type: 'questions',
        iconurl: checkmark_image_path(graded?(question_or_student))
      }).merge(option_data(question_or_student))
    }
  end
end
