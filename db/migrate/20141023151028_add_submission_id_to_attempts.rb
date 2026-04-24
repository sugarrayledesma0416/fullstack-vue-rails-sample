class AddSubmissionIdToAttempts < ActiveRecord::Migration[4.2]
  def change
    add_column :attempts, :submission_id, :integer
  end
end
