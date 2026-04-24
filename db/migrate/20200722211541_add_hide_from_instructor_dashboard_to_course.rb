class AddHideFromInstructorDashboardToCourse < ActiveRecord::Migration[5.2]
  def up
    add_column :courses, :hide_from_instructor_dashboard, :boolean
    change_column_default :courses, :hide_from_instructor_dashboard, false
  end
  def down
    remove_column :courses, :hide_from_instructor_dashboard
  end
end
