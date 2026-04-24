class AddIndexToNotificationsForDashboard < ActiveRecord::Migration[4.2]
  def self.up
    add_index :notifications, [:user_id,:section_id,:created_at], :name => 'by_user_section_and_created_at'
  end

  def self.down
    remove_index :notifications, :name => :by_user_section_and_created_at
  end
end
