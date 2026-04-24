class AddAssignmentGroupToActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :assignment_group, :string
  end
end
