class AddCourseEventsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :course_events do |t|
      t.integer  :course_id
      t.string   :name
      t.date     :date
      t.integer  :added_by
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :course_events 
  end
end
