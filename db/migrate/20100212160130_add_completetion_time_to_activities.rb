class AddCompletetionTimeToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :minutes_to_complete, :integer
  end

  def self.down
    remove_column :activities, :minutes_to_complete
  end
end
