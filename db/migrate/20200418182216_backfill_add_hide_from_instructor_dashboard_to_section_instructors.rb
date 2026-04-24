class BackfillAddHideFromInstructorDashboardToSectionInstructors < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    SectionInstructor.in_batches.update_all hide_from_instructor_dashboard: false
  end
end
