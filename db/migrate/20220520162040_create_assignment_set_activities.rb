class CreateAssignmentSetActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :assignment_set_activities do |t|
      t.integer :assignment_set_rank
      t.references :activity
      t.references :assignment_set

      t.timestamps
    end
  end
end
