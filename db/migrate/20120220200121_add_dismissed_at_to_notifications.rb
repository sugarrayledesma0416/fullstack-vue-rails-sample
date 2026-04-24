class AddDismissedAtToNotifications < ActiveRecord::Migration[4.2]
  def self.up
    add_column :notifications, :dismissed_at, :datetime
  end

  def self.down
    remove_column :notifications, :dismissed_at
  end
end
