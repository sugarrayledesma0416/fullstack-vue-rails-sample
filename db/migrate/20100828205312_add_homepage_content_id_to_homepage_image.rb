class AddHomepageContentIdToHomepageImage < ActiveRecord::Migration[4.2]
  def self.up
    add_column :homepage_images, :homepage_content_id, :integer
  end

  def self.down
    remove_column :homepage_images, :homepage_content_id
  end
end
