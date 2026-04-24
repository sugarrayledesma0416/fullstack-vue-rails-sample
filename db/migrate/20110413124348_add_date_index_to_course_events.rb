class AddDateIndexToCourseEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_index :course_events, :date, :name => 'date_order'
  end

  def self.down
    remove_index :course_events, :date_order
  end
end
