class AddSubmissionLengthToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :submission_length, :integer
  end

  def self.down
    remove_column :scores, :submission_length
  end
end
