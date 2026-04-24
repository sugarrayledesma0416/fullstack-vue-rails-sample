class BackfillAddHideFromInstructorDashboardToCourse < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Course.unscoped.in_batches do |relation|
      relation.update_all hide_from_instructor_dashboard: false
      sleep(0.01)
    end
  end
end
