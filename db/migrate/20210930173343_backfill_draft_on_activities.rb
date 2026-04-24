class BackfillDraftOnActivities < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    InstructorCreatedActivity.in_batches do |relation|
      relation.update_all draft: false
      sleep(0.01)
    end
  end
end
