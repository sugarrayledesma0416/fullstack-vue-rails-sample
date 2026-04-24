class AddWarnedToRedemptionStatus < ActiveRecord::Migration[4.2]
  def self.up
    add_column :redemption_statuses, :warned, :boolean, :default => false
  end

  def self.down
    remove_column :redemption_statuses, :warned
  end
end
