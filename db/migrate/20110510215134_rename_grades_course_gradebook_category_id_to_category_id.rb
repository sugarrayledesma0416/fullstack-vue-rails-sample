class RenameGradesCourseGradebookCategoryIdToCategoryId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :grades, :course_gradebook_category_id, :category_id
  end

  def self.down
    rename_column :grades, :category_id, :course_gradebook_category_id
  end
end
