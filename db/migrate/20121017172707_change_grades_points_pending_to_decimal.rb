class ChangeGradesPointsPendingToDecimal < ActiveRecord::Migration[4.2]
  def self.up
    change_column :grades, :points_pending, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
  end

  def self.down
    change_column :grades, :points_pending, :integer, :default => 0
  end
end
