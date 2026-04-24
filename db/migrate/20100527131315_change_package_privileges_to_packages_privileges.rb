class ChangePackagePrivilegesToPackagesPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :package_privileges, :packages_privileges
  end

  def self.down
    rename_table :packages_privileges, :package_privileges
  end
end
