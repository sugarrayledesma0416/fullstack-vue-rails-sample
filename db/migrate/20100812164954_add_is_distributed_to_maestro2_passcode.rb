class AddIsDistributedToMaestro2Passcode < ActiveRecord::Migration[4.2]
  def self.up
    add_column :maestro2_passcodes, :is_distributed, :boolean, :default => true
  end

  def self.down
    remove_column :maestro2_passcodes, :is_distributed
  end
end
