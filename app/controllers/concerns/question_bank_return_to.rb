module QuestionBankReturnTo
  extend ActiveSupport::Concern

  private def assign_return_to
    topic = @topic || @question_bank_topic
    name = topic.name.html_decode.strip_tags

    session[:activity_return] = {
      'label' => "Return to Topic: #{name}",
      'url' => question_bank_topic_path(id: topic.id)
    }
  end

  private def assign_revision_return_to
    session[:activity_return] = {
      'label' => "Return to Question Bank: #{@question_bank.title}",
      'url' => question_bank_topic_question_bank_question_bank_revisions_path(
        question_bank_topic_id: @topic.id,
        question_bank_id: @question_bank.id
      )
    }
  end
end
