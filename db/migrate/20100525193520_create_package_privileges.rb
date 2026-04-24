class CreatePackagePrivileges < ActiveRecord::Migration[4.2]
  def self.up
    create_table :package_privileges do |t|
      t.integer :package_id
      t.integer :privilege_id
      t.integer :months_duration

      t.timestamps
    end
  end

  def self.down
    drop_table :package_privileges
  end
end
