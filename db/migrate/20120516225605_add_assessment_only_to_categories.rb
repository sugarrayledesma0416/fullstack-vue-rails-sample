class AddAssessmentOnlyToCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :assessment_only, :boolean
  end

  def self.down
    remove_column :categories, :assessment_only
  end
end
