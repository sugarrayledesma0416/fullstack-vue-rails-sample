class UpdateAttemptsSubmissionColumnsToBigint < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.live?
      safety_assured do
        change_column :attempts, :submission_id, :bigint
        change_column :attempts, :saved_submission_id, :bigint
      end
    end
  end

  def down
    unless Rails.env.live?
      safety_assured do
        change_column :attempts, :submission_id, :integer
        change_column :attempts, :saved_submission_id, :integer
      end
    end
  end
end
