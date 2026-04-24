class RenamePermissionsToPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    rename_table "permissions", "privileges"
  end

  def self.down
    rename_table "privileges", "permissions"
  end
end
