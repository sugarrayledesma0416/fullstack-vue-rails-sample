class DuplicateImageIntoImagePathForHomepageContent < ActiveRecord::Migration[4.2]
  def self.up
    add_column :homepage_contents, :image_path, :string
  end

  def self.down
    remove_column :homepage_contents, :image_path, :string
  end
end
