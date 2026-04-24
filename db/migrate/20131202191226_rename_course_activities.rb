class RenameCourseActivities < ActiveRecord::Migration[4.2]
  def up
    rename_table :course_activities, :course_library_activities
  end

  def down
    rename_table :course_library_activities, :course_activities
  end

end
