class AddNoteItemIdToActivityNotes < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activity_notes, :note_item_id, :string
  end

  def self.down
    remove_column :activity_notes, :note_item_id
  end
end
