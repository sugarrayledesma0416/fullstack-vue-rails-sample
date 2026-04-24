class DropAttemptIntegrityLogs < ActiveRecord::Migration[4.2]
  def up
    drop_table :attempt_integrity_logs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
