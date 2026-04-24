class RemoveHomePageImages < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "homepage_images"
  end

  def self.down
    create_table "homepage_images", :force => true do |t|
      t.string   "filename"
      t.string   "content_type"
      t.integer  "size"
      t.integer  "width"
      t.integer  "height"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "homepage_content_id"
    end    
  end
end
