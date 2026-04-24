class AddGroupNameToCourseGradebookCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :group_name, :string
  end

  def self.down
    remove_column :course_gradebook_categories, :group_name
  end
end
