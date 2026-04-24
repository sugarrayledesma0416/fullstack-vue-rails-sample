class AddDaysToShowAssignmentDueDateColumnToSections < ActiveRecord::Migration[4.2]
  def change
    add_column :sections, :days_to_show_assignment_due_date, :int, default: nil
  end
end
