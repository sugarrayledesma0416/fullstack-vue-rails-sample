class AddTimestampsToOneRosterLinkedSections < ActiveRecord::Migration[5.2]
  def change
    add_column :one_roster_linked_sections, :created_at, :datetime, null: false
    add_column :one_roster_linked_sections, :updated_at, :datetime, null: false
  end
end
