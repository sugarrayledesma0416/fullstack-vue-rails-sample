class AddCourseIdIndexToCourseEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_index :course_events, :course_id
  end

  def self.down
    remove_index :course_events, :course_id
  end
end
