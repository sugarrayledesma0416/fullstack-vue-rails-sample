class AddIndividuallyAssignableToAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :assignments, :individually_assignable, :boolean, default: false
  end
end
