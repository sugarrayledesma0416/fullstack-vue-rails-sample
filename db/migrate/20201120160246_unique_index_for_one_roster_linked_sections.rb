class UniqueIndexForOneRosterLinkedSections < ActiveRecord::Migration[5.2]
  def change
    add_index :one_roster_linked_sections,
              %i[class_external_id course_external_id school_id],
              unique: true,
              name: :idx_one_roster_linked_sections_on_class_and_course_and_school
  end
end
