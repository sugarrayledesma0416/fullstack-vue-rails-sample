class AddIsDeactivatedToPasscodes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passcodes , :is_deactivated, :boolean , :default => false
  end

  def self.down
    remove_column  :passcodes , :is_deactivated
  end
end
