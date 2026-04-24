class AddCombinedToTours < ActiveRecord::Migration[4.2]
  def self.up
    add_column :tours, :combined, :boolean, :default => false
  end

  def self.down
    remove_column :tours, :combined
  end
end
