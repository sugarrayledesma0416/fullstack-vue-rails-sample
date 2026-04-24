class AddAssignmentRandomizePerStudent < ActiveRecord::Migration[5.2]
  def up
    add_column :assignments, :randomize_per_student, :boolean, null: false
    change_column_default :assignments, :randomize_per_student, false
  end

  def down
    remove_column :assignments, :randomize_per_student
  end
end
