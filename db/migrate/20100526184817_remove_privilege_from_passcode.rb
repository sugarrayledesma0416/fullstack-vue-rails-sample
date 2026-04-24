class RemovePrivilegeFromPasscode < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :passcodes, :privilege_id
  end

  def self.down
    add_column :passcodes, :privilege_id, :integer
  end
end
