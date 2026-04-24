class ChangeScoresPointsEarnedToFloat < ActiveRecord::Migration[4.2]
  def self.up
    change_column :scores, :points_earned, :float
  end

  def self.down
    change_column :scores, :points_earned, :integer
  end
end
