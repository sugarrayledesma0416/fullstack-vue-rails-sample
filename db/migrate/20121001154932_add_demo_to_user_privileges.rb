class AddDemoToUserPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    add_column :user_privileges, :demo, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :user_privileges, :demo
  end
end
