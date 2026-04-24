class CreateAssignmentFilters < ActiveRecord::Migration[4.2]
  def self.up
    create_table :assignment_filters do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :lesson_id
      t.timestamps
    end
  end

  def self.down
    drop_table :assignment_filters
  end
end
