class AddIsArchivedToOneRosterLinkedSections < ActiveRecord::Migration[5.2]
  def up
    add_column :one_roster_linked_sections, :is_archived, :boolean
    change_column_default :one_roster_linked_sections, :is_archived, false
  end

  def down
    remove_column :one_roster_linked_users, :is_archived
  end
end
