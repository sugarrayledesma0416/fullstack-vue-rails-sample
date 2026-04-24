class CreateAdvertiserContents < ActiveRecord::Migration[4.2]
  def self.up
    create_table :advertiser_contents do |t|
      t.string :title
      t.string :image
      t.text :body

      t.timestamps
    end
  end

  def self.down
    drop_table :advertiser_contents
  end
end
