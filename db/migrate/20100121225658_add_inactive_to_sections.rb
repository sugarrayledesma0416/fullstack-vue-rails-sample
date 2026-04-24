class AddInactiveToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :inactive, :boolean, :default => false
  end

  def self.down
    remove_column :sections, :inactive
  end
end
