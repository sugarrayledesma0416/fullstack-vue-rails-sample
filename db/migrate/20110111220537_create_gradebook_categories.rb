class CreateGradebookCategories < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :gradebook_categories do |t|
      t.string    :name
      t.integer   :course_id
      t.integer   :rank, :default => 1
      t.boolean   :is_archived, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :gradebook_categories
  end
end
