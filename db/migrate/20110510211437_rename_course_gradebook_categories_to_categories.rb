class RenameCourseGradebookCategoriesToCategories < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :course_gradebook_categories, :categories
  end

  def self.down
    rename_table :categories, :course_gradebook_categories
  end
end
