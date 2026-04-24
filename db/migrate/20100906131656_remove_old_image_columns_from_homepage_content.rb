class RemoveOldImageColumnsFromHomepageContent < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :homepage_contents, :image
    remove_column :homepage_contents, :image_path
  end

  def self.down
    add_column :homepage_contents, :image, :string
    add_column :homepage_contents, :image_path, :string
  end
end
