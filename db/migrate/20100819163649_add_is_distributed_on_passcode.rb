class AddIsDistributedOnPasscode < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passcodes, :is_distributed, :boolean, :default => true
  end

  def self.down
    remove_column :passcodes, :is_distributed
  end
end
