class AddTocEntryLocationToAssignmentFilter < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignment_filters, :toc_entry_location, :integer
  end

  def self.down
    remove_column :assignment_filters, :toc_entry_location
  end
end
