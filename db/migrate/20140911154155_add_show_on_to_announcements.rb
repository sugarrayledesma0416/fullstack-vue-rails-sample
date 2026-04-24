class AddShowOnToAnnouncements < ActiveRecord::Migration[4.2]
  def self.up
    add_column :announcements, :show_on, :date
  end

  def self.down
    remove_column :announcements, :show_on
  end
end
