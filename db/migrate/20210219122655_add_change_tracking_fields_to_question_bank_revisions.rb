class AddChangeTrackingFieldsToQuestionBankRevisions < ActiveRecord::Migration[5.2]
  def change
    add_column :question_bank_revisions, :changed_by_id, :integer
    add_column :question_bank_revisions, :upload_filename, :string
    add_column :question_bank_revisions, :uploaded_csv, :blob
  end
end
