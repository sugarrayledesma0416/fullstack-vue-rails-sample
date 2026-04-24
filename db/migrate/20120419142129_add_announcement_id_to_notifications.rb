class AddAnnouncementIdToNotifications < ActiveRecord::Migration[4.2]
  def self.up
    add_column :notifications, :announcement_id, :integer, :null => true
  end

  def self.down
    remove_column :notifications, :announcement_id
  end
end
