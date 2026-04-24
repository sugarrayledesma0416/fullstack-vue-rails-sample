class AddStatusToQuestionBankRevisions < ActiveRecord::Migration[5.2]
  def change
    add_column :question_bank_revisions, :status, :string
  end
end
