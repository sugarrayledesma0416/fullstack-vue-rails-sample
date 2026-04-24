class RenameCourseGradebookCategoryLabelNameToName < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :course_gradebook_categories, :label_name, :name
  end

  def self.down
    rename_column :course_gradebook_categories, :name, :label_name
  end
end
