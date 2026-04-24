class AddTimeSpentToScores < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :time_spent, :integer, :default => 0
  end

  def self.down
    remove_column :scores, :time_spent
  end
end
