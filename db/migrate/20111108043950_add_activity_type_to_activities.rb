class AddActivityTypeToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :activity_type, :string
  end

  def self.down
    remove_column :activities, :activity_type
  end
end
