class AddPointsEarnedCreditToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :points_earned_credit, :float, :default => nil
  end

  def self.down
    remove_column :scores, :points_earned_credit
  end
end
