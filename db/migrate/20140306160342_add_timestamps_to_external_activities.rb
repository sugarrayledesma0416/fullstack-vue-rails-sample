class AddTimestampsToExternalActivities < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:external_activities)
  end
end
