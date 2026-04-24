class LinkPasscodesToPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passcodes, :privilege_id, :integer
    remove_column :passcodes, :access_type
  end

  def self.down
    add_column :passcodes, :access_type, :string
    remove_column :passcodes, :privilege_id
  end
end
