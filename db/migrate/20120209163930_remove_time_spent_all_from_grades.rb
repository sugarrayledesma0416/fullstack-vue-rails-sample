class RemoveTimeSpentAllFromGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grades, :time_spent_all
  end

  def self.down
    add_column :grades, :time_spent_all, :integer, :default => 0
  end
end
