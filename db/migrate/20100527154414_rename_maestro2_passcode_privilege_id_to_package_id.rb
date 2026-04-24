class RenameMaestro2PasscodePrivilegeIdToPackageId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :maestro2_passcodes, :privilege_id, :package_id
  end

  def self.down
    rename_column :maestro2_passcodes, :package_id, :privilege_id
  end
end
