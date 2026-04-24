class AddTitleToActivityNotes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activity_notes, :title, :text
  end

  def self.down
    remove_column :activity_notes, :title
  end
end
