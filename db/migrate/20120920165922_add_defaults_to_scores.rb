class AddDefaultsToScores < ActiveRecord::Migration[4.2]
  def self.up
    change_column :scores, :points_earned, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
    change_column :scores, :points_earned_credit, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
    change_column :scores, :points_possible, :integer, :default => 0, :null => false
    change_column :scores, :assigned, :boolean, :default => false, :null => false
    change_column :scores, :late, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :scores, :points_earned, :decimal, :precision => 8, :scale => 2
    change_column :scores, :points_earned_credit, :decimal, :precision => 8, :scale => 2
    change_column :scores, :points_possible, :integer 
    change_column :scores, :assigned, :boolean
    change_column :scores, :late, :boolean
  end
end
