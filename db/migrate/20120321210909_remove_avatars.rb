class RemoveAvatars < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :avatars
  end

  def self.down
    create_table "avatars", :force => true do |t|
      t.integer  "parent_id"
      t.string   "content_type"
      t.string   "filename"
      t.string   "thumbnail"
      t.integer  "size"
      t.integer  "width"
      t.integer  "height"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "profile_id"
    end

    add_index "avatars", ["parent_id"], :name => "index_avatars_on_parent_id"
    add_index "avatars", ["profile_id"], :name => "index_avatars_on_profile_id"
  end
end
