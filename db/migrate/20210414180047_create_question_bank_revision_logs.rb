class CreateQuestionBankRevisionLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :question_bank_revision_logs do |t|
      t.integer :question_bank_revision_id
      t.integer :user_id
      t.string :status

      t.timestamps
    end
    add_index :question_bank_revision_logs, :question_bank_revision_id
  end
end
