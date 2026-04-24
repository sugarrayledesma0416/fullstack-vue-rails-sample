class AddLateToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :late, :boolean, :default => false
  end

  def self.down
    remove_column :scores, :late
  end
end
