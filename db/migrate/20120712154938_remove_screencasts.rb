class RemoveScreencasts < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :screencasts
  end

  def self.down
    create_table :screencasts do |t|
      t.string   "title",                          :null => false
      t.string   "path",                           :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "is_instructor"
      t.integer  "rank"
      t.string   "topic"
      t.integer  "height",        :default => 480
      t.integer  "width",         :default => 640
      t.integer  "parent_id"
    end
  end
end
