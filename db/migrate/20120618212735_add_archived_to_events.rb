class AddArchivedToEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :archived, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :events, :archived
  end
end
