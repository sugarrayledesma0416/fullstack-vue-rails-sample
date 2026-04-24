class DropPackagesPrivileges < ActiveRecord::Migration[4.2]
  def change
    drop_table :packages_privileges
  end
end
