class AddTimeSpentToAttempt < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attempts, :time_spent, :integer, :default => 0
  end

  def self.down
    remove_column :attempts, :time_spent
  end
end
