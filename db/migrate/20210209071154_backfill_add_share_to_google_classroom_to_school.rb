class BackfillAddShareToGoogleClassroomToSchool < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    School.unscoped.in_batches do |relation|
      relation.update_all(
        share_to_google_classroom: false,
        share_to_google_classroom_last_updated_at: DateTime.now.utc
      )
      sleep(0.1)
    end
  end
end
