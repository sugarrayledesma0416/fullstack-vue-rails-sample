class AddPercentToGradebookCourseCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :percent, :float
  end

  def self.down
    remove_column :course_gradebook_categories, :percent
  end
end
