class AddIndexToAssignmentsForDashboard < ActiveRecord::Migration[4.2]
  def self.up
    add_index :assignments, [:study_schedule_id,:due_date], :name => 'by_study_schedule_and_due_date'
  end

  def self.down
    remove_index :assignments, :name => :by_study_schedule_and_due_date
  end
end
