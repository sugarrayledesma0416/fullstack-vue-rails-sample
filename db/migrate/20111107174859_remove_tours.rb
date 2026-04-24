class RemoveTours < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :tours
  end

  def self.down
    create_table "tours", :force => true do |t|
      t.boolean  "instructor", :default => false
      t.integer  "program_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "url"
      t.boolean  "combined",   :default => false
    end    
  end
end
