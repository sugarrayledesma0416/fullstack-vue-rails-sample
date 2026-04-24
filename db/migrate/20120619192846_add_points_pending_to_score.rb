class AddPointsPendingToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :points_pending, :integer, :default => 0
  end

  def self.down
    remove_column :scores, :points_pending
  end
end
