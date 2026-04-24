class CreateHomepageImages < ActiveRecord::Migration[4.2]
  def self.up
    create_table :homepage_images do |t|
      t.string :filename
      t.string :content_type
      t.integer :size
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end

  def self.down
    drop_table :homepage_images
  end
end
