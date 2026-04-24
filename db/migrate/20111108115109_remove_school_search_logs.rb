class RemoveSchoolSearchLogs < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "school_search_logs"
  end

  def self.down
    create_table "school_search_logs", :force => true do |t|
      t.string   "name"
      t.integer  "user_id"
      t.string   "city"
      t.string   "state"
      t.string   "country"
      t.string   "data",        :limit => 1000
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "comment"
      t.integer  "category_id",                 :default => 1
      t.integer  "status",                      :default => 1
    end    
  end
end
