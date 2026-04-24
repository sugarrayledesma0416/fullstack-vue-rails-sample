class RemovePointsEarnedAllFromGrades < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :grades, :points_earned_all
  end

  def self.down
    add_column :grades, :points_earned_all, :float
  end
end
