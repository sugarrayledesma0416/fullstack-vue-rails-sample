class AddHideFromInstructorDashboardToSectionInstructors < ActiveRecord::Migration[5.2]
  def up
    add_column :section_instructors, :hide_from_instructor_dashboard, :boolean
    change_column_default :section_instructors, :hide_from_instructor_dashboard, false
  end

  def down
    remove_column :section_instructors, :hide_from_instructor_dashboard
  end
end
