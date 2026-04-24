class RemoveCourseEventsTable < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :course_events
  end

  def self.down
    create_table "course_events", :force => true do |t|
      t.integer  "course_id"
      t.string   "name"
      t.date     "date"
      t.integer  "added_by"

      t.timestamps
    end
  end
end
