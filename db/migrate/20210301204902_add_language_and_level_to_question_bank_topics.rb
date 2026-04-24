class AddLanguageAndLevelToQuestionBankTopics < ActiveRecord::Migration[5.2]
  def change
    add_column :question_bank_topics, :language, :string
    add_column :question_bank_topics, :level, :string
  end
end
