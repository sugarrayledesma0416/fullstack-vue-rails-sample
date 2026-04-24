class AddAssessmentGradeAvailabiltyToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :assessment_grade_availability, :string
  end

  def self.down
    remove_column :activities, :assessment_grade_availability
  end
end
