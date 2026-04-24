class CreateCourseActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :course_activities do |t|
      t.integer :activity_id
      t.integer :course_id

      t.timestamps
    end

    add_index :course_activities, [:activity_id, :course_id]
  end
end
