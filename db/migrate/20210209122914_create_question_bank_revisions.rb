class CreateQuestionBankRevisions < ActiveRecord::Migration[5.2]
  def change
    create_table :question_bank_revisions do |t|
      t.references :activity
      t.text :content_json
      t.timestamps
    end
  end
end
