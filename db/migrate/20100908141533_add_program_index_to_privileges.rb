class AddProgramIndexToPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    add_index :privileges, :program_id
  end

  def self.down
    remove_index :privileges, :program_id
  end
end
