class CreateHomepageContents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :homepage_contents do |t|
      t.string :location
      t.string :title
      t.string :image
      t.string :link
      t.text :summary
      t.boolean :active

      t.timestamps
    end
  end

  def self.down
    drop_table :homepage_contents
  end
end
