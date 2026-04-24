class MoveAssignmentActivitiesToAssignable < ActiveRecord::Migration[4.2]
  def self.up
    ActiveRecord::Base.connection.execute("UPDATE assignments SET assignable_id = activity_id, assignable_type = 'Activity';")
  end

  def self.down
    ActiveRecord::Base.connection.execute("UPDATE assignments SET activity_id = assignable_id;")
  end
end
