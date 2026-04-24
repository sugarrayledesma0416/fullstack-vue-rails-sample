class AddPenaltyToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :penalty, :integer, :default => 0
    add_column :scores, :adjusted, :boolean, :default => false
  end

  def self.down
    remove_column :scores, :penalty
    remove_column :scores, :adjusted
  end
end
