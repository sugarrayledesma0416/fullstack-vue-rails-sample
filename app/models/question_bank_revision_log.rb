class QuestionBankRevisionLog < ApplicationRecord
  belongs_to :question_bank_revision

  def user_full_name
    User.find(user_id).full_name
  end
end
