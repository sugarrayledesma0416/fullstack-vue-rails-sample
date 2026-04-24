class AddQuestionBankTopicIdToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :question_bank_topic_id, :bigint
  end
end
