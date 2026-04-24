class AddSavedSubmissionIdToAttempts < ActiveRecord::Migration[4.2]
  def change
    add_column :attempts, :saved_submission_id, :integer
  end
end
