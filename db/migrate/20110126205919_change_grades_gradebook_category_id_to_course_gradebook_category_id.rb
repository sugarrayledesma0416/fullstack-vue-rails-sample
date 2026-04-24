class ChangeGradesGradebookCategoryIdToCourseGradebookCategoryId < ActiveRecord::Migration[4.2]
  def self.up
    add_column    :grades, :course_gradebook_category_id, :integer, :null => false
    remove_column :grades, :gradebook_category_id
  end

  def self.down
    add_column    :grades, :gradebook_category_id, :integer, :null => false
    remove_column :grades, :course_gradebook_category_id
  end
end
