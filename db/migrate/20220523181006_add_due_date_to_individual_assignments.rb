class AddDueDateToIndividualAssignments < ActiveRecord::Migration[5.2]
  def change
    add_column :individual_assignments, :due_date, :date, null: true
  end
end
