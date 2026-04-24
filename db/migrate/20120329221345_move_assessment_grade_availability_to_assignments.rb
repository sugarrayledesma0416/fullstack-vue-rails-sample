class MoveAssessmentGradeAvailabilityToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :activities, :assessment_grade_availability
    add_column :assignments, :grade_availability, :string
  end

  def self.down
    add_column :activities, :assessment_grade_availability, :string
    remove_column :assignments, :grade_availability
  end
end
