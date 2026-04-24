class RenameScoringRulesetsCourseGradebookCategoryIdToCategoryId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :scoring_rulesets, :course_gradebook_category_id, :category_id
  end

  def self.down
    rename_column :scoring_rulesets, :category_id, :course_gradebook_category_id
  end
end
