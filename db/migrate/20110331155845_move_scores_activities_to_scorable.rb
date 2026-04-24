class MoveScoresActivitiesToScorable < ActiveRecord::Migration[4.2]
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE scores SET scorable_id = activity_id, scorable_type = 'Activity';")
  end

  def self.down
    ActiveRecord::Base.connection.execute("UPDATE scores SET activity_id = scorable_id;")
  end
end
