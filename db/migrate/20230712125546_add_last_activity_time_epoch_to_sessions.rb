class AddLastActivityTimeEpochToSessions < ActiveRecord::Migration[6.1]
  def change
    add_column :sessions, :last_activity_time_epoch, :integer
  end
end
