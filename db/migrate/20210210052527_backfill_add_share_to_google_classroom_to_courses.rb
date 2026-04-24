class BackfillAddShareToGoogleClassroomToCourses < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Course.unscoped.in_batches do |relation|
      relation.update_all share_to_google_classroom: true
      sleep(0.01)
    end
  end
end
