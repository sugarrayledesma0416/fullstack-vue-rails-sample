class BackfillAddRosteringAndSchoolToLtiPlatforms < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    Lti::Platform.unscoped.in_batches do |relation|
      relation.update_all rostering: false
      sleep(0.1)
    end
  end
end
