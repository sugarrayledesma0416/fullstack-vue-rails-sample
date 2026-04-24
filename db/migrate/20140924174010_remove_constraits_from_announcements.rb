class RemoveConstraitsFromAnnouncements < ActiveRecord::Migration[4.2]
  def change
    change_column_null :announcements, :course_id, true
  end
end
