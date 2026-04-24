class RemoveFilenameFromActivity < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :activities, :content_filename
  end

  def self.down
    add_column :activities, :content_filename, :string
  end
end
