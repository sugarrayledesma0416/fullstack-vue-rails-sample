class RenameAssignmentsCourseGradebookCategoryIdToCategoryId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :assignments, :course_gradebook_category_id, :category_id
  end

  def self.down
    rename_column :assignments, :category_id, :course_gradebook_category_id
  end
end
