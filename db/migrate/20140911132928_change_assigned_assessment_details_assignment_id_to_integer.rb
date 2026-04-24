class ChangeAssignedAssessmentDetailsAssignmentIdToInteger < ActiveRecord::Migration[4.2]
  def up
    change_column :assigned_assessment_details, :assignment_id, :integer, null: false
  end

  def down
    change_column :assigned_assessment_details, :assignment_id, :string
  end
end
