class BackfillAddDisabledToLtiPlatforms < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Lti::Platform.unscoped.in_batches do |relation|
      relation.update_all disabled: false
      sleep(0.01)
    end
  end
end
