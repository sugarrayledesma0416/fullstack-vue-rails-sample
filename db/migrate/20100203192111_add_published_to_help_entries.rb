class AddPublishedToHelpEntries < ActiveRecord::Migration[4.2]
  def self.up
    add_column :help_entries, :published, :boolean
  end

  def self.down
    remove_column :help_entries, :published
  end
end
