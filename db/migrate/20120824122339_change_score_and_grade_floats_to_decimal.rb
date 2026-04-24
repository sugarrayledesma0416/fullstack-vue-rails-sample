class ChangeScoreAndGradeFloatsToDecimal < ActiveRecord::Migration[4.2]
  def self.up
    change_column :scores, :points_earned, :decimal, :precision => 8, :scale => 2
    change_column :scores, :points_earned_credit, :decimal, :precision => 8, :scale => 2
    change_column :grades, :points_earned_current, :decimal, :precision => 8, :scale => 2
    change_column :grades, :points_earned_credit, :decimal, :precision => 8, :scale => 2
    change_column :feedback_items, :points_earned, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    change_column :scores, :points_earned, :float
    change_column :scores, :points_earned_credit, :float
    change_column :grades, :points_earned_current, :float
    change_column :grades, :points_earned_credit, :float
    change_column :feedback_items, :points_earned, :float
  end
end
