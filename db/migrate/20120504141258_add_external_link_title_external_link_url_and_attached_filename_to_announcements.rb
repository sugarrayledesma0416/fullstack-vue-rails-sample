class AddExternalLinkTitleExternalLinkUrlAndAttachedFilenameToAnnouncements < ActiveRecord::Migration[4.2]
  def self.up
    add_column :announcements, :external_link_title, :string, :null => true
    add_column :announcements, :external_link_url, :string, :null => true
    add_column :announcements, :attached_filename, :string, :null => true
  end

  def self.down
    remove_column :announcements, :external_link_title
    remove_column :announcements, :external_link_url
    remove_column :announcements, :attached_filename
  end
end
