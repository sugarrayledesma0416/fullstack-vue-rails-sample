class AddTimestampsToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :created_at, :datetime
    add_column :activities, :updated_at, :datetime

    update_query = "UPDATE activities SET created_at = NOW(), updated_at = NOW();"
    ActiveRecord::Base.connection.execute(update_query)
  end

  def self.down
    remove_column :activities, :created_at
    remove_column :activities, :updated_at
  end
end
