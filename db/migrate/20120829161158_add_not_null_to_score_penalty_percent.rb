class AddNotNullToScorePenaltyPercent < ActiveRecord::Migration[4.2]
  def self.up
    update_query = "UPDATE scores SET penalty_percent = 0 WHERE penalty_percent IS NULL;"
    ActiveRecord::Base.connection.execute(update_query)

    change_column :scores, :penalty_percent, :integer, :default => 0, :null => false
  end

  def self.down
    change_column :scores, :penalty_percent, :integer, :default => 0, :null => true
  end
end
