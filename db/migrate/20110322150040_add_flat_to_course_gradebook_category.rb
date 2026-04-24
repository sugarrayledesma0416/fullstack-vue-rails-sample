class AddFlatToCourseGradebookCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :course_gradebook_categories, :flat, :boolean, :default => 0
  end

  def self.down
    remove_column :course_gradebook_categories, :flat
  end
end
