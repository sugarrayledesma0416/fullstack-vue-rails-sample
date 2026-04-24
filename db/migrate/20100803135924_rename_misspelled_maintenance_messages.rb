class RenameMisspelledMaintenanceMessages < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :maintanence_messages, :maintenance_messages
  end

  def self.down
    rename_table :maintenance_messages, :maintanence_messages
  end
end
