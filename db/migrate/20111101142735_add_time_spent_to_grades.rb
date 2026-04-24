class AddTimeSpentToGrades < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grades, :time_spent_current, :integer, :default => 0
    add_column :grades, :time_spent_all, :integer, :default => 0
  end

  def self.down
    remove_column :grades, :time_spent_current
    remove_column :grades, :time_spent_all
  end
end
