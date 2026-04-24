class AddPrivilegeIdToMaestro2Passcodes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :maestro2_passcodes, :privilege_id, :integer
  end

  def self.down
    remove_column :maestro2_passcodes, :privilege_id
  end
end
