class RenameAttachedFilenameToFileName < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :announcements, :attached_filename, :file_name
  end

  def self.down
    rename_column :announcements, :file_name, :attached_filename
  end
end
