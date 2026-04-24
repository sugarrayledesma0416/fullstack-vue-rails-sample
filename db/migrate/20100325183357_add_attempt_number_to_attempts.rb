class AddAttemptNumberToAttempts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attempts, :attempt_number, :integer, :default => 0
  end

  def self.down
    remove_column :attempts, :attempt_number
  end
end
