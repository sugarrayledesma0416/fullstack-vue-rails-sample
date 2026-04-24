class AddIsArchivedResourcesTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :is_archived, :boolean, :default => 0
  end

  def self.down
    remove_column :resources, :is_archived
  end
end
