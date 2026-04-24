class RenameAssessmentOnlyToAllowsAssessments < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :categories, :assessment_only, :allows_assessments
  end

  def self.down
    rename_column :categories, :allows_assessments, :assessment_only
  end
end
