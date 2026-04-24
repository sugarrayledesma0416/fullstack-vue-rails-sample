class AddLabelToCourseGradebookCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :label_name, :string
  end

  def self.down
    remove_column :course_gradebook_categories, :label_name
  end
end
