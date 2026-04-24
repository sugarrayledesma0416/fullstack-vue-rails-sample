class AddIsArchivedToAssignments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :is_archived, :boolean, :default => false
  end

  def self.down
    remove_column :assignments, :is_archived
  end
end
