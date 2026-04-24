class DropOldContentTables < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :advertiser_contents
    drop_table :language_contents
    drop_table :publisher_contents
  end

  def self.down
    create_table :language_contents do |t|
      t.string :title
      t.string :image
      t.text :body

      t.timestamps
    end
    create_table :publisher_contents do |t|
      t.string :title
      t.string :image
      t.text :body

      t.timestamps
    end
    create_table :advertiser_contents do |t|
      t.string :title
      t.string :image

      t.timestamps
    end    
  end
end
