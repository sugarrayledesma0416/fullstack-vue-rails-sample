class CreateAssignedAssessmentDetails < ActiveRecord::Migration[4.2]
  def change
    create_table :assigned_assessment_details do |t|
      t.string  :assignment_id
      t.string  :password
      t.integer :time_limit
      t.timestamps
    end
  end
end
