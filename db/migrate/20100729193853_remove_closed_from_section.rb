class RemoveClosedFromSection < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :sections, :closed
  end

  def self.down
    add_column :sections, :closed, :boolean, :default => 0
  end
end
