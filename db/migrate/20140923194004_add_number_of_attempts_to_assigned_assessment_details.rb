class AddNumberOfAttemptsToAssignedAssessmentDetails < ActiveRecord::Migration[4.2]
  def change
    add_column :assigned_assessment_details, :number_of_attempts, :integer, :default => 1
  end
end
