class DropPrivileges < ActiveRecord::Migration[4.2]
  def change
    drop_table :privileges
  end
end
