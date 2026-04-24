class AddCurrentFieldsToGrades < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grades, :points_earned_current, :integer
    add_column :grades, :points_possible_current, :integer
    add_column :grades, :activity_count_current, :integer
    rename_column :grades, :activity_count, :activity_count_all
    rename_column :grades, :points_earned, :points_earned_all
    rename_column :grades, :points_possible, :points_possible_all
  end

  def self.down
    rename_column :grades, :points_possible_all, :points_possible
    rename_column :grades, :points_earned_all, :points_earned
    rename_column :grades, :activity_count_all, :activity_count
    remove_column :grades, :activity_count_current
    remove_column :grades, :points_possible_current
    remove_column :grades, :points_earned_current
  end
end
