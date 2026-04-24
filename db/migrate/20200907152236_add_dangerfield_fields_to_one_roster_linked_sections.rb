class AddDangerfieldFieldsToOneRosterLinkedSections < ActiveRecord::Migration[5.2]
  def up
    add_column :one_roster_linked_sections, :guid, :string
    add_column :one_roster_linked_sections, :sync_token, :integer, limit: 8
    add_column :one_roster_linked_sections, :request_id, :string
    add_column :one_roster_linked_sections, :school_id, :integer

    change_column_default :one_roster_linked_sections, :sync_token, 0
    add_index :one_roster_linked_sections, :guid
    add_index :one_roster_linked_sections, :school_id
  end

  def down
    remove_index :one_roster_linked_sections, :guid
    remove_index :one_roster_linked_sections, :school_id

    remove_column :one_roster_linked_sections, :guid
    remove_column :one_roster_linked_sections, :sync_token
    remove_column :one_roster_linked_sections, :request_id
    remove_column :one_roster_linked_sections, :school_id
  end
end
