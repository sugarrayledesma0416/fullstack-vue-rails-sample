class AddPointsEarnedCreditToGrade < ActiveRecord::Migration[4.2]
  def self.up
    add_column :grades, :points_earned_credit, :float, :default => nil
  end

  def self.down
    remove_column :grades, :points_earned_credit
  end
end
