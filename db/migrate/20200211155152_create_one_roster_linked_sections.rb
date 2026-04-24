class CreateOneRosterLinkedSections < ActiveRecord::Migration[5.2]
  def change
    create_table :one_roster_linked_sections do |t|
      t.integer :section_id, null: false
      t.string :class_external_id, null: false
      t.string :course_external_id, null: false
      t.string :academic_session_external_id
    end
    add_index :one_roster_linked_sections, :section_id
  end
end
