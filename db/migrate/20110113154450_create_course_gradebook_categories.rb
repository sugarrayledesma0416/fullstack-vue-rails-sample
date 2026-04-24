class CreateCourseGradebookCategories < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :course_gradebook_categories do |t|
      t.integer   :course_id
      t.integer   :gradebook_category_id
      t.integer   :rank, :default => 0, :null => false
      t.boolean   :is_archived, :default => false

      t.timestamps
    end    
  end

  def self.down
    drop_table :course_gradebook_categories
  end
end
