class DropUserPrivileges < ActiveRecord::Migration[4.2]
  def change
    drop_table :user_privileges
  end
end
