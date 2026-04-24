class RenameScoresPenaltyToPenaltyPercent < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :scores, :penalty, :penalty_percent
  end

  def self.down
    rename_column :scores, :penalty_percent, :penalty
  end
end
