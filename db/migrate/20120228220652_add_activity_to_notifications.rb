class AddActivityToNotifications < ActiveRecord::Migration[4.2]
  def self.up
    add_column :notifications, :activity_id, :integer, :null => true
  end

  def self.down
    remove_column :notifications, :activity_id
  end
end
