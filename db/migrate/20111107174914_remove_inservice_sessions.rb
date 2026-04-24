class RemoveInserviceSessions < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :inservice_sessions
  end

  def self.down
    create_table "inservice_sessions", :force => true do |t|
      t.string   "audience",     :default => "Supersites"
      t.string   "session_type"
      t.datetime "session_date"
      t.boolean  "archived",     :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end    
  end
end
