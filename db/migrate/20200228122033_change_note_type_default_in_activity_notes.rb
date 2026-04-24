class ChangeNoteTypeDefaultInActivityNotes < ActiveRecord::Migration[5.2]
  def change
    change_column_default :activity_notes, :note_type, from: 'sidebar', to: 'collapsed'
  end
end
