class AddGradeMethodToCourseGradebookCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :grade_method, :string , :default => 'points'
  end

  def self.down
    remove_column :course_gradebook_categories, :grade_method
  end
end
