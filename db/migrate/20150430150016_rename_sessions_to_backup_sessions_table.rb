class RenameSessionsToBackupSessionsTable < ActiveRecord::Migration[4.2]
  def up
    remove_index :sessions, :session_id
    remove_index :sessions, :updated_at
    rename_table :sessions, :backup_sessions
  end

  def down
    rename_table :backup_sessions, :sessions
    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end
end
