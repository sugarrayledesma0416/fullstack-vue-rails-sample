class AllowNullCourseGradebookCategoryIdInGrades < ActiveRecord::Migration[4.2]
  def self.up
    change_column :grades, :course_gradebook_category_id, :integer, :null => true
  end

  def self.down
    change_column :grades, :course_gradebook_category_id, :integer, :null => false
  end
end
