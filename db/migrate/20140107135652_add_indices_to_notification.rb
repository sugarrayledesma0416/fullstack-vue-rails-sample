class AddIndicesToNotification < ActiveRecord::Migration[4.2]
  def change
    add_index :notifications, :announcement_id
    add_index :notifications, :dismissed_at
  end
end
