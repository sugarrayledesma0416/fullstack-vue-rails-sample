class AddPasswordToAssignments < ActiveRecord::Migration[4.2]
  def up
    #add_column :assignments, :password, :string
  end

  def down
    #remove_column :assignments, :password
  end
end
