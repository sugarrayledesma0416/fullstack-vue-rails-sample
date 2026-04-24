class EnlargeScheduledJobArgs < ActiveRecord::Migration[4.2]
  def up
    # TEXT -> MEDIUMTEXT
    change_column :scheduled_jobs, :args, :text, :limit => 16777215
  end

  def down
    # MEDIUMTEXT -> TEXT
    change_column :scheduled_jobs, :args, :text, :limit => 65535
  end
end
