class AddImageAltTextToHomepageContents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :homepage_contents, :image_alt_text, :string
  end

  def self.down
    remove_column :homepage_contents, :image_alt_text
  end
end
