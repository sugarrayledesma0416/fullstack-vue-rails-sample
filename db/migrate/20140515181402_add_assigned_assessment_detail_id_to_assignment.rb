class AddAssignedAssessmentDetailIdToAssignment < ActiveRecord::Migration[4.2]
  def change
    add_column :assignments, :assigned_assessment_detail_id, :integer
  end
end
