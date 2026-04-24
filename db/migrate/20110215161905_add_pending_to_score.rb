class AddPendingToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :pending, :boolean, :default => false
  end

  def self.down
    remove_column :scores, :pending
  end
end
