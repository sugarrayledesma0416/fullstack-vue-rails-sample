class AddGroupToAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :group, :string
  end
end
