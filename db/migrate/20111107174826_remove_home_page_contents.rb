class RemoveHomePageContents < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "homepage_contents"
  end

  def self.down
    create_table "homepage_contents", :force => true do |t|
      t.string   "location"
      t.string   "title"
      t.string   "link"
      t.text     "summary"
      t.boolean  "active"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "account_type",   :default => "All", :null => false
      t.string   "image_alt_text"
      t.string   "link_text"
    end    
  end
end
