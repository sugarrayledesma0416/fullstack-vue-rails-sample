class AddClassCancelledColumnToAnnouncements < ActiveRecord::Migration[4.2]
  def change
    add_column :announcements, :class_cancelled, :boolean, default: false
  end
end
