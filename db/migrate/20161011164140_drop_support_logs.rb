class DropSupportLogs < ActiveRecord::Migration[4.2]
  def change
    drop_table :support_logs
  end
end
