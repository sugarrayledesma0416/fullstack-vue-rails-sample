class CreateMediaLinks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :media_links do |t|
      t.integer  :activity_id
      t.integer  :media_item_id

      t.timestamps
    end    
  end

  def self.down
     drop_table :media_links
  end
end
