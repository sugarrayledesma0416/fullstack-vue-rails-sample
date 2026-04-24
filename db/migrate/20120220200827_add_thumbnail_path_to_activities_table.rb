class AddThumbnailPathToActivitiesTable < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :thumbnail_path, :string
  end

  def self.down
    remove_column :activities, :thumbnail_path, :string
  end
end
