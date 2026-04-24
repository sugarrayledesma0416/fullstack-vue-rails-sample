class AddedDefaultValuesToGrades < ActiveRecord::Migration[4.2]
  def self.up
    change_column :grades, :points_earned_current, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
    change_column :grades, :points_earned_credit, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
    change_column :grades, :points_possible_current, :integer, :default => 0, :null => false
    change_column :grades, :activity_count_current, :integer, :default => 0, :null => false
  end

  def self.down
    change_column :grades, :points_earned_current, :decimal, :precision => 8, :scale => 2
    change_column :grades, :points_earned_credit, :decimal, :precision => 8, :scale => 2
    change_column :grades, :points_possible_current, :integer
    change_column :grades, :activity_count_current, :integer
  end
end
