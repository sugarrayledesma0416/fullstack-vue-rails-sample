class RenameLabelTable < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :gradebook_categories, :labels
    rename_column :course_gradebook_categories, :gradebook_category_id, :label_id
  end

  def self.down
    rename_table :labels, :gradebook_categories
    rename_column :course_gradebook_categories, :label_id, :gradebook_category_id
  end
end
