class RemoveIsArchivedFromAssignments < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :assignments, :is_archived
  end

  def self.down
    add_column :assignments, :is_archived, :boolean
  end
end
