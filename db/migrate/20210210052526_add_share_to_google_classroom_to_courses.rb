class AddShareToGoogleClassroomToCourses < ActiveRecord::Migration[5.2]
  def up
    add_column :courses, :share_to_google_classroom, :boolean
    change_column_default :courses, :share_to_google_classroom, true
  end

  def down
    remove_column :courses, :share_to_google_classroom
  end
end
