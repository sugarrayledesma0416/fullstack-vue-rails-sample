class DropStressLogs < ActiveRecord::Migration[4.2]
  def change
    drop_table :stress_logs
  end
end
