class ChangePrivilegesProgramIdToAcceptNull < ActiveRecord::Migration[4.2]
  def self.up
    change_column :privileges, :program_id, :integer, :null => true
  end

  def self.down
    change_column :privileges, :program_id, :integer, :null => false
  end
end
