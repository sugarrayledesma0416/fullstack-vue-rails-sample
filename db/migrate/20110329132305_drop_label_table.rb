class DropLabelTable < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :labels
  end

  def self.down
    create_table "labels", :force => true do |t|
      t.string   "name"
      t.boolean  "is_archived", :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
