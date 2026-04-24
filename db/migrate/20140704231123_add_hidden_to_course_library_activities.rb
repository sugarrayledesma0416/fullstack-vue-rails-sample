class AddHiddenToCourseLibraryActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :course_library_activities, :hidden, :boolean, :default => true
  end
end
