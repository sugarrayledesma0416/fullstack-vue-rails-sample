class AddMediaItems < ActiveRecord::Migration[4.2]
  def self.up
    create_table :media_items do |t|
      t.string   :filename
      t.string   :media_type
      t.integer  :size
      t.integer  :width
      t.integer  :height
      t.text     :transcript
      
      t.timestamps
    end    
  end

  def self.down
    drop_table :media_items
  end
end
