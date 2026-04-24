class ChangeGradesPointsEarnedToFloat < ActiveRecord::Migration[4.2]
  def self.up
    change_column :grades, :points_earned_all, :float
    change_column :grades, :points_earned_current, :float
  end

  def self.down
    change_column :grades, :points_earned_all, :integer
    change_column :grades, :points_earned_current, :integer
  end
end
