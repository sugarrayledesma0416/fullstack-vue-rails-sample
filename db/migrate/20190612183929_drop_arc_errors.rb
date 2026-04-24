class DropArcErrors < ActiveRecord::Migration[4.2]
  def up
    drop_table :arc_errors
  end

  def down
    create_table :arc_errors do |t|
      t.integer  "user_id"
      t.string   "error_message"
      t.string   "error_type"
      t.string   "flash_version"
      t.string   "browser"
      t.string   "browser_version"
      t.string   "platform"
      t.string   "http_referer"
    end
  end
end
