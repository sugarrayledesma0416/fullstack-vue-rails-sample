class CreateActivityNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :activity_notes do |t|
      t.references :user
      t.references :activity
      t.references :program
      t.string     :note_type, :null => false, :default => 'sidebar'
      t.integer    :focused_course_id
      t.text       :body_text
      t.integer    :cms_revision_id

      t.timestamps
    end
  end
end
