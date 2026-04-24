class AddQuestionBankRevisionIdToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :question_bank_revision_id, :bigint
  end
end
