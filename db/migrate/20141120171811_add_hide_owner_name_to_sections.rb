class AddHideOwnerNameToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :hide_owner_name, :boolean, :default => false
  end

  def self.down
    remove_column :sections, :hide_owner_name
  end
end
